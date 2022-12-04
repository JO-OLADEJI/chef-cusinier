// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/interfaces/IERC165.sol";
import "./ISteak.sol";

/// @title IChefCusinier
/// @author Joshua Oladeji <analogdev.eth>
interface IChefCusinier is IERC165 {
    enum TransactionType {
        DEPOSIT,
        WITHDRAWAL
    }

    /// @notice Struct storing the info of a user (yield farmer)
    /// - id: Address of the user
    /// - capital: Amount of user's ERC20 tokens staked in this contract
    /// - cachedSteak: Cached pending rewards yet to be claimed by user
    /// - blockRewardIndex: Index of the last block in `_txBlocks[]` used to calculate user's steak rewards
    /// - untrackedRewardBlocks: Block numbers of harvests in blocks not tracked in `_txBlocks[]`
    struct User {
        address id;
        uint256 capital;
        uint256 cachedSteak;
        uint256 blockRewardIndex;
        uint256[] untrackedRewardBlocks;
    }

    /// @notice Struct storing the info of a pool (LP token)
    /// - capitalToken: Address of pool
    /// - rewardWeight: Weight specifying the fraction of steakPerBlock minted as rewards to users of a pool
    struct Pool {
        IERC20 capitalToken;
        uint96 rewardWeight;
    }

    // /// @notice Amount of stake tokens deposited by yield farmers
    // function trackedTvl() external view returns (uint256);

    // /// @notice Amout of reward tokens created per block
    // function rewardPerBlock() external view returns (uint256);

    // /// @notice Address of ERC20 token staked in this yield farm
    // function stakeToken() external view returns (IERC20);

    // /// @notice Address of ERC2O token to be minted to yield farmers
    // function rewardToken() external view returns (IRewardToken);

    // /// @notice Returns stored info of yield farmer
    // /// @param _farmer Address of yield farmer
    // /// @return _farmerInfo Info of the yield farmer
    // function getFarmer(address _farmer)
    //     external
    //     view
    //     returns (Farmer memory _farmerInfo);

    // /// @notice Returns accumulated rewards claimable by yield farmer
    // /// @dev Convenience function for frontend
    // /// @param _farmer Address of yield farmer
    // /// @return _accumulatedRewards Rewards claimable by yield farmer
    // function getAccumulatedRewards(address _farmer)
    //     external
    //     view
    //     returns (uint256 _accumulatedRewards);

    // /// @notice Claims accumulated rewards of `msg.sender`
    // function claimRewards() external;

    // /// @notice Claims a portion of accumulated rewards to `msg.sender`
    // /// @dev _amount must not be higher than accumulated rewards
    // /// @param _amount Amount of accumulated rewards to claim
    // function claimRewards(uint256 _amount) external;

    // /// @notice Stake tokens for proportional rewards
    // /// @dev YieldFarm should have up to `_amount` allowance on `msg.sender` tokens
    // /// @param _amount Amount of tokens to stake
    // /// Note: This function does not claim rewards along with deposit
    // function deposit(uint256 _amount) external;

    // /// @notice Stake tokens for proportional rewards and claim all accumulated rewards
    // /// @dev YieldFarm should have up to `_amount` allowance on `msg.sender` tokens
    // /// @param _amount Amount of tokens to stake
    // function depositAndClaimRewards(uint256 _amount) external;

    // /// @notice Withdraw all `msg.sender` staked tokens from YieldFarm
    // /// Note: This function does not claim rewards along with withdrawal
    // function withdraw() external;

    // /// @notice Withdraw a portion of `msg.sender` staked tokens from YieldFarm
    // /// @dev _amount must not be higher than `msg.sender` staked tokens in YieldFarm
    // /// @param _amount Amount of tokens to withdraw
    // /// Note: This function does not claim rewards along with withdrawal
    // function withdraw(uint256 _amount) external;

    // /// @notice Withdraw all `msg.sender` staked tokens and claim all accumulated rewards
    // function withdrawAndClaimRewards() external;
}
