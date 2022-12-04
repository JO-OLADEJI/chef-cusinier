// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin/token/ERC20/IERC20.sol";
import "./interfaces/IChefCusinier.sol";
import "./interfaces/ISteak.sol";

contract ChefCusinier is IChefCusinier {
    IERC20 public capitalToken;
    ISteak public steakToken;

    uint256 public steakPerBlock;
    uint256 public trackedCapital;
    /// @notice Number used to achieve precision when dividing
    uint256 private constant DIVISION_PRECISION = 1e12;

    uint256[] private _txBlocks;

    mapping(address => User) private _users;
    mapping(uint256 => uint256) private _blockCapitalSnapshot;
    mapping(uint256 => mapping(address => uint256))
        private _untrackedClaimedSteak;

    constructor(
        IERC20 _capitalToken,
        ISteak _steakToken,
        uint256 _steakPerBlock
    ) {
        require(_steakPerBlock > 0, "invalid steak rewards per block");

        capitalToken = _capitalToken;
        steakToken = _steakToken;
        steakPerBlock = _steakPerBlock;
    }

    function getUntrackedClaimedSteak(uint256 _block, address _user)
        external
        view
        returns (uint256)
    {
        return _untrackedClaimedSteak[_block][_user];
    }

    function getPendingSteak(address _user) external view returns (uint256) {
        User storage user = _getUser(_user);
        return _getPendingSteak(user) + user.cachedSteak;
    }

    function getUser(address _id) external view returns (User memory) {
        return _getUser(_id);
    }

    function supportsInterface(bytes4 _interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return _interfaceId == type(IChefCusinier).interfaceId;
    }

    function deposit(uint256 _amount) external {
        User storage user = _getUser(msg.sender);
        require(_amount > 0, "amount too low");
        require(
            capitalToken.balanceOf(msg.sender) >= _amount,
            "insufficient balance"
        );

        if (user.id == address(0)) {
            user.id = msg.sender;
        }
        _syncTxBlocks(_amount, TransactionType.DEPOSIT);

        // cache steak rewards
        user.cachedSteak += _getPendingSteak(user);
        user.blockRewardIndex = _txBlocks.length - 1;
        user.capital += _amount;

        _clearUntrackedRewards(user);

        capitalToken.transferFrom(user.id, address(this), _amount);
    }

    function withdraw(uint256 _amount) external {
        User storage user = _getUser(msg.sender);
        require(_amount > 0, "amount too low");
        require(user.capital >= _amount, "insufficient capital");

        _syncTxBlocks(_amount, TransactionType.WITHDRAWAL);

        // cache steak rewards
        user.cachedSteak += _getPendingSteak(user);
        user.blockRewardIndex = _txBlocks.length - 1;
        user.capital -= _amount;

        _clearUntrackedRewards(user);

        _safeCapitalWithdraw(_amount, user.id);
    }

    function claimPendingSteak() external {
        _claimPendingSteak();
    }

    function _syncTxBlocks(uint256 _amount, TransactionType _txType) private {
        if (
            _txBlocks.length == 0 ||
            (_txBlocks.length > 0 &&
                _txBlocks[_txBlocks.length - 1] != block.timestamp)
        ) {
            _txBlocks.push(block.timestamp);
        }

        if (_txType == TransactionType.DEPOSIT) {
            trackedCapital += _amount;
        } else if (_txType == TransactionType.WITHDRAWAL) {
            trackedCapital -= _amount;
        }

        _blockCapitalSnapshot[block.timestamp] = trackedCapital;
    }

    function _getUser(address _id) private view returns (User storage) {
        return _users[_id];
    }

    function _safeCapitalWithdraw(uint256 _amount, address _to) private {
        if (capitalToken.balanceOf(address(this)) >= _amount) {
            capitalToken.transfer(_to, _amount);
        } else {
            capitalToken.transfer(_to, capitalToken.balanceOf(address(this)));
        }
    }

    function _clearUntrackedRewards(User storage _user) private {
        if (_user.untrackedRewardBlocks.length > 0) {
            uint256 noOfUntrackedRewardClaims = _user
                .untrackedRewardBlocks
                .length;

            for (uint256 i = noOfUntrackedRewardClaims; i > 0; ) {
                delete _untrackedClaimedSteak[
                    _user.untrackedRewardBlocks[i - 1]
                ][_user.id];
                _user.untrackedRewardBlocks.pop();

                unchecked {
                    --i;
                }
            }
        }
    }

    function _claimPendingSteak() private {
        User storage user = _getUser(msg.sender);

        // get sum of user's pending steak and cached steak
        uint256 claimableSteak = _getPendingSteak(user) + user.cachedSteak;

        // if no transaction is recorded for this timestamp, add it to the user's untracked reward blocks
        if (_txBlocks[_txBlocks.length - 1] < block.timestamp) {
            if (
                user.untrackedRewardBlocks.length == 0 ||
                (user.untrackedRewardBlocks.length > 0 &&
                    user.untrackedRewardBlocks[
                        user.untrackedRewardBlocks.length - 1
                    ] !=
                    block.timestamp)
            ) {
                user.untrackedRewardBlocks.push(block.timestamp);
            }
            _untrackedClaimedSteak[block.timestamp][user.id] +=
                claimableSteak -
                user.cachedSteak;
        } else {
            user.blockRewardIndex = _txBlocks.length - 1;
        }
        user.cachedSteak = 0;

        steakToken.serve(user.id, claimableSteak);
    }

    function _getPendingSteak(User memory _user)
        private
        view
        returns (uint256)
    {
        // no reward is accumulated when the farmer stake is `0`. In cases where a farmer has unclaimed
        // rewards, the cached rewards will be used internally
        if (
            _user.capital == 0 ||
            _txBlocks[_user.blockRewardIndex] == block.timestamp
        ) return 0;

        uint256 pendingSteak;

        // calculate pending rewards to the last tracked block
        if (_txBlocks.length == 2 && _user.blockRewardIndex == 0) {
            pendingSteak +=
                (steakPerBlock *
                    _user.capital *
                    (_txBlocks[1] - _txBlocks[0]) *
                    DIVISION_PRECISION) /
                _blockCapitalSnapshot[_txBlocks[0]];
        } else if (_txBlocks.length > 2) {
            for (
                uint256 i = _user.blockRewardIndex;
                i < _txBlocks.length - 1;

            ) {
                pendingSteak +=
                    (steakPerBlock *
                        _user.capital *
                        (_txBlocks[i + 1] - _txBlocks[i]) *
                        DIVISION_PRECISION) /
                    _blockCapitalSnapshot[_txBlocks[i]];

                unchecked {
                    ++i;
                }
            }
        }

        // add rewards accumulated from latest tracked `_txBlock` up to current block
        if (block.timestamp > _txBlocks[_txBlocks.length - 1]) {
            pendingSteak +=
                (steakPerBlock *
                    _user.capital *
                    (block.timestamp - _txBlocks[_txBlocks.length - 1]) *
                    DIVISION_PRECISION) /
                _blockCapitalSnapshot[_txBlocks[_txBlocks.length - 1]];
        }

        pendingSteak /= DIVISION_PRECISION;

        // subtract any claimed rewards from the calculated pending rewards
        if (_user.untrackedRewardBlocks.length > 0) {
            for (uint256 i = 0; i < _user.untrackedRewardBlocks.length; ) {
                pendingSteak -= _untrackedClaimedSteak[
                    _user.untrackedRewardBlocks[i]
                ][_user.id];

                unchecked {
                    ++i;
                }
            }
        }

        return pendingSteak;
    }
}
