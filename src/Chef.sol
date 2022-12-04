// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/security/ReentrancyGuard.sol";
import "./interfaces/IChef.sol";
import "./interfaces/ISteak.sol";

/**
 *
 * @title Chef
 * @author Joshua Oladeji <analogdev.eth>
 * @notice Chef contract is a simpler implementation of SushiSwap's infamous `MasterChef` contract.
 * This contract is responsible for distributing `Steak` rewards to stakers of `Capital` token only.
 * For an implementation that distrubutes `Steak` rewards to stakers of multiple LP tokens,
 * checkout the `ChefCusinier` contract.
 * Chef contract calculates rewards per seconds. This is because of the varying block speeds on EVM
 * compatible chains. To calculate rewards using blocks, simply change appearances of `block.timestamp`
 * to `block.number`
 *
 * Happy cooking and may the gods of OpenZeppelin security be with you 🤝
 */

contract Chef is IChef, ReentrancyGuard {
    /// @notice Token being staked to get rewards in `Steak` tokens
    IERC20 public override capitalToken;
    /// @notice `Steak` token being given out as reward to stakers of `Capital` token
    ISteak public override steakToken;

    /// @notice Number of `Steak` tokens given out as rewards every second
    uint256 public override steakPerSecond;
    /// @notice Number of `Capital` tokens tracked from user's `deposit` and `withdrawal`
    uint256 public override trackedCapital;
    /// @notice Number used to achieve some level of precision when calculating rewards
    uint256 private constant DIVISION_PRECISION = 1e12;

    /// @notice Timestamp in which `deposit` or `withdrawal` function is called
    uint256[] private _txTimestamps;

    /// @notice Address => User Info
    mapping(address => User) private _users;
    /// @notice `deposit` or `withdrawal` timestamp => number of `capital` tokens in contract
    mapping(uint256 => uint256) private _timestampCapitalSnapshot;
    /// @notice `block.timestamp` => user address => untracked `Steak` tokens claimed
    mapping(uint256 => mapping(address => uint256))
        private _untrackedClaimedSteak;

    /// @notice Constructor
    /// @param _capitalToken Address of `Capital` token to be staked
    /// @param _steakToken Address of `Steak` token given out as rewards to stakers
    /// @param _steakPerSecond Amount of `Steak` tokens given out per seconds are rewards
    constructor(
        IERC20 _capitalToken,
        ISteak _steakToken,
        uint256 _steakPerSecond
    ) {
        require(_steakPerSecond > 0, "invalid steak per second");

        capitalToken = _capitalToken;
        steakToken = _steakToken;
        steakPerSecond = _steakPerSecond;
    }

    /* View Functions */

    /// @notice Returns the number of `Steak` tokens a user can claim at the time of function call
    /// @param _user Address of user
    /// @return Number of claimable `Steak` tokens;
    function getPendingSteak(address _user)
        external
        view
        override
        returns (uint256)
    {
        User storage user = _getUser(_user);
        return _getPendingSteak(user) + user.cachedSteak;
    }

    /// @notice Returns the user info of an address
    /// @param _id Address of user
    /// @return User info struct of address
    function getUser(address _id) external view override returns (User memory) {
        return _getUser(_id);
    }

    /// @dev See {IERC165 - supportsInterface}
    function supportsInterface(bytes4 _interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return _interfaceId == type(IChef).interfaceId;
    }

    /* External Functions */

    /// @notice Stake `Capital` tokens to receive a portion of `Steak` tokens minted per block as rewards
    /// @param _amount Number of `Capital` tokens to deposit
    function deposit(uint256 _amount) external override nonReentrant {
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
        user.blockRewardIndex = _txTimestamps.length - 1;
        user.capital += _amount;

        _clearUntrackedRewards(user);

        capitalToken.transferFrom(user.id, address(this), _amount);

        emit Deposit(user.id, _amount);
    }

    /// @notice Unstake `Capital` tokens from contract
    /// @param _amount Number of `Capital` tokens to withdraw
    function withdraw(uint256 _amount) external override nonReentrant {
        User storage user = _getUser(msg.sender);
        require(_amount > 0, "amount too low");
        require(user.capital >= _amount, "insufficient capital");

        _syncTxBlocks(_amount, TransactionType.WITHDRAWAL);

        // cache steak rewards
        user.cachedSteak += _getPendingSteak(user);
        user.blockRewardIndex = _txTimestamps.length - 1;
        user.capital -= _amount;

        _clearUntrackedRewards(user);

        _safeCapitalWithdraw(_amount, user.id);

        emit Withdrawal(user.id, _amount);
    }

    /// @notice Claims pending `Steak` rewards (if any) of msg.sender
    function claimPendingSteak() external override nonReentrant {
        _claimPendingSteak();
    }

    /* Private Functions */

    /// @notice Adds timestamps of `deposit` and `withdrawal` transaction to `_txTimestamps[]`
    /// @notice Increases and Decreses `trackedCapital` by amount based on transaction type
    /// @param _amount Amount of `Capital` tokens to track
    /// @param _txType Transactio type which is either `deposit` or `withdrawal`
    function _syncTxBlocks(uint256 _amount, TransactionType _txType) private {
        if (
            _txTimestamps.length == 0 ||
            (_txTimestamps.length > 0 &&
                _txTimestamps[_txTimestamps.length - 1] != block.timestamp)
        ) {
            _txTimestamps.push(block.timestamp);
        }

        if (_txType == TransactionType.DEPOSIT) {
            trackedCapital += _amount;
        } else if (_txType == TransactionType.WITHDRAWAL) {
            trackedCapital -= _amount;
        }

        _timestampCapitalSnapshot[block.timestamp] = trackedCapital;
    }

    /// @notice Returns the user info of an address
    /// @param _id Address of user
    /// @return User info struct of address
    function _getUser(address _id) private view returns (User storage) {
        return _users[_id];
    }

    /// @notice Safely transfers the amount of `Capital` tokens from contract to `to`
    /// @param _amount Amount of `Capital` tokens to withdraw
    /// @param _to Address to sent `Capital` tokens to
    function _safeCapitalWithdraw(uint256 _amount, address _to) private {
        if (capitalToken.balanceOf(address(this)) >= _amount) {
            capitalToken.transfer(_to, _amount);
        } else {
            capitalToken.transfer(_to, capitalToken.balanceOf(address(this)));
        }
    }

    /// @notice Clears `untrackedRewardBlocks[]` present in a user's info struct
    /// @param _user User info of user
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

    /// @notice Claims pending `Steak` rewards (if any) of msg.sender
    function _claimPendingSteak() private {
        User storage user = _getUser(msg.sender);

        // get sum of user's pending steak and cached steak
        uint256 claimableSteak = _getPendingSteak(user) + user.cachedSteak;

        // if no transaction is recorded for this timestamp, add it to the user's untracked reward blocks
        if (_txTimestamps[_txTimestamps.length - 1] < block.timestamp) {
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
            user.blockRewardIndex = _txTimestamps.length - 1;
        }
        user.cachedSteak = 0;

        steakToken.serve(user.id, claimableSteak);

        emit ClaimRewards(user.id, claimableSteak);
    }

    /// @notice Computes the number of `Steak` tokens accrued to a user from time user's last `deposit` or `withdrawal`
    /// @param _user User info of user
    function _getPendingSteak(User memory _user)
        private
        view
        returns (uint256)
    {
        // no reward is accumulated when the farmer stake is `0`. In cases where a farmer has unclaimed
        // rewards, the cached rewards will be used internally
        if (
            _user.capital == 0 ||
            _txTimestamps[_user.blockRewardIndex] == block.timestamp
        ) return 0;

        uint256 pendingSteak;

        // calculate pending rewards to the last tracked block
        if (_txTimestamps.length == 2 && _user.blockRewardIndex == 0) {
            pendingSteak +=
                (steakPerSecond *
                    _user.capital *
                    (_txTimestamps[1] - _txTimestamps[0]) *
                    DIVISION_PRECISION) /
                _timestampCapitalSnapshot[_txTimestamps[0]];
        } else if (_txTimestamps.length > 2) {
            for (
                uint256 i = _user.blockRewardIndex;
                i < _txTimestamps.length - 1;

            ) {
                pendingSteak +=
                    (steakPerSecond *
                        _user.capital *
                        (_txTimestamps[i + 1] - _txTimestamps[i]) *
                        DIVISION_PRECISION) /
                    _timestampCapitalSnapshot[_txTimestamps[i]];

                unchecked {
                    ++i;
                }
            }
        }

        // add rewards accumulated from latest tracked `_txBlock` up to current block
        if (block.timestamp > _txTimestamps[_txTimestamps.length - 1]) {
            pendingSteak +=
                (steakPerSecond *
                    _user.capital *
                    (block.timestamp -
                        _txTimestamps[_txTimestamps.length - 1]) *
                    DIVISION_PRECISION) /
                _timestampCapitalSnapshot[
                    _txTimestamps[_txTimestamps.length - 1]
                ];
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

// add function to claim rewards when depositing and withdrawing tokens
// add bonus multiplier
// add protocol minting while claiming rewards
