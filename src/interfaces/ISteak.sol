// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin/token/ERC20/IERC20.sol";
import "./IChefCusinier.sol";

interface ISteak is IERC20 {
    /// @notice ChefCusinier contract responsible for minting reward tokens
    function chef() external view returns (IChefCusinier);

    /// @notice Function to mint new tokens to a user
    /// @param _account Address to mint tokens to
    /// @param _amount Amount of tokens to mint
    /// NOTE: Amount should be formatted to the right number of decimals
    function serve(address _account, uint256 _amount) external;

    /// @notice Set address of ChefCusinier contract responsible for minting reward tokens
    /// @param _chef Address of ChefCusinier contract
    function setChef(IChefCusinier _chef) external;
}
