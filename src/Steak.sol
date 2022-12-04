// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/access/Ownable.sol";
import "./interfaces/ISteak.sol";
import "./interfaces/IChef.sol";

/// @title Steak
/// @notice Token contract used by Chef to distrubute rewards
/// @author Joshua Oladeji <analogdev.eth>
contract Steak is ISteak, ERC20, Ownable {
    /// @notice ChefCusinier contract responsible for minting reward tokens
    IChef public override chef;

    modifier onlyChef() {
        require(msg.sender == address(chef));
        _;
    }

    /// @notice Constructor
    constructor() ERC20("Steak", "STK") {}

    /// @notice Set address of ChefCusinier contract responsible for minting reward tokens
    /// @param _chef Address of ChefCusinier contract
    function setChef(IChef _chef) external override onlyOwner {
        chef = _chef;
    }

    /// @notice Function to mint new tokens to a user
    /// @param _account Address to mint tokens to
    /// @param _amount Amount of tokens to mint
    /// NOTE: Amount should be formatted to the right number of decimals
    function serve(address _account, uint256 _amount)
        external
        override
        onlyChef
    {
        _mint(_account, _amount);
    }
}
