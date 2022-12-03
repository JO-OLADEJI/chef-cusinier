// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IChefCusinier.sol";

contract ChefCusinier is IChefCusinier {
    enum TransactionType {
        DEPOSIT,
        WITHDRAWAL
    }

    uint256 public trackedCapital;

    uint256[] private _txBlocks;

    mapping(uint256 => uint256) _blockCapitalSnapshot;

    mapping(address => User) private _users;

    function getUser(address _id) external view returns (User memory) {
        return _getUser(_id);
    }

    function deposit(uint256 _amount) external {
        User storage user = _getUser(msg.sender);
        require(_amount > 0, "amount too low");
        require(
            stakeToken.balanceOf(msg.sender) >= _amount,
            "insufficient balance"
        );

        user.id == address(0) && user.id = msg.sender;
        _syncTxBlocks(_amount, TransactionType.DEPOSIT);

        // cache steak rewards
        user.cachedSteak += _getPendingSteak(user);
        user.blockRewardIndex = _txBlocks.length - 1;
        user.capital += _amount;

        // empty user.untrackedRewardBlocks
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

        // empty user.untrackedRewardBlocks
    }

    function _syncTxBlocks(uint256 _amount, TransactionType _txType) private {
        if (
            _txBlocks.length == 0 ||
            (_txBlocks.length > 0 &&
                _txBlocks[_txBlocks.length - 1] != block.timestamp)
        ) {
            _txBlocks.push(block.timestamp);
        }

        if (_txType = TransactionType.DEPOSIT) {
            trackedCapital += _amount;
        } else if (_txType = TransactionType.WITHDRAWAL) {
            trackedCapital -= _amount;
        }

        _blockCapitalSnapshot[block.timestamp] = trackedCapital;
    }

    function _getUser(address _id) private view returns (User memory) {
        return _users[_id];
    }

    function _getPendingSteak(User memory _user)
        private
        view
        returns (uint256)
    {
        // no reward is accumulated when the farmer stake is `0`. In cases where a farmer has unclaimed
        // rewards, the cached rewards will be used internally
        if (
            _farmer.stake == 0 ||
            _txBlocks[_farmer.blockRewardIndex] == block.timestamp
        ) return 0;

        // 1. calculate the pending rewards to the last tracked block
        // 2. calculate the pending reward from last tracked block to current timestamp
        // 3. subtract any claimed rewards from the sum of 1 & 2

        // if (_txBlocks.length == 2 && _farmer.blockRewardIndex != 1) {
        //     _accumulatedRewards +=
        //         (rewardPerBlock *
        //             _farmer.stake *
        //             (_txBlocks[1] - _txBlocks[0]) *
        //             DIVISION_PRECISION) /
        //         _blockTvlSnapshot[_txBlocks[0]];
        // } else if (_txBlocks.length > 2) {
        //     for (
        //         uint256 i = _farmer.blockRewardIndex;
        //         i < _txBlocks.length - 1;

        //     ) {
        //         _accumulatedRewards +=
        //             (rewardPerBlock *
        //                 _farmer.stake *
        //                 (_txBlocks[i + 1] - _txBlocks[i]) *
        //                 DIVISION_PRECISION) /
        //             _blockTvlSnapshot[_txBlocks[i]];
        //         unchecked {
        //             ++i;
        //         }
        //     }
        // }

        // // add rewards accumulated from latest tracked `_txBlock` up to current block
        // if (block.timestamp > _txBlocks[_txBlocks.length - 1]) {
        //     _accumulatedRewards +=
        //         (rewardPerBlock *
        //             _farmer.stake *
        //             (block.timestamp - _txBlocks[_txBlocks.length - 1]) *
        //             DIVISION_PRECISION) /
        //         _blockTvlSnapshot[_txBlocks[_txBlocks.length - 1]];
        // }

        // _accumulatedRewards /= DIVISION_PRECISION;

        // if (_farmer.untrackedRewardBlocks.length > 0) {
        //     for (uint256 i = 0; i < _farmer.untrackedRewardBlocks.length; ) {
        //         _accumulatedRewards -= _untrackedBlockHarvests[
        //             _farmer.untrackedRewardBlocks[i]
        //         ][_farmer.id];
        //         unchecked {
        //             ++i;
        //         }
        //     }
        // }
    }
}
