// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/access/Ownable.sol";
import "./interfaces/ISteak.sol";
import "./interfaces/IChefCusinier.sol";

/// @title Steak
/// @notice Token contract used by Chef to distrubute rewards
/// @author Joshua Oladeji <analogdev.eth>
contract Steak is ISteak, ERC20, Ownable {
    /// @dev See {ISteak - chef}
    IChefCusinier public override chef;

    modifier onlyChef() {
        require(msg.sender == address(chef));
        _;
    }

    /// @notice Constructor
    constructor() ERC20("Steak", "STK") {}

    /// @dev See {ISteak - setChef}
    function setChef(IChefCusinier _chef) external override onlyOwner {
        chef = _chef;
    }

    /// @dev See {ISteak - serve}
    function serve(address _account, uint256 _amount)
        external
        override
        onlyChef
    {
        _mint(_account, _amount);
    }
}
