// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/access/Ownable.sol";
import "./interfaces/ISteak.sol";

/**
 *
 * @title Steak
 * @notice Token contract used by Chef/ChefCusinier to distrubute rewards
 * @author Joshua Oladeji <analogdev.eth>
 *
 */

contract Steak is ISteak, ERC20, Ownable {
    /// @notice Chef/ChefCusinier contract responsible for minting reward tokens
    address public override chef;

    modifier onlyChef() {
        require(msg.sender == address(chef));
        _;
    }

    /// @notice Constructor
    constructor() ERC20("Steak", "STK") {}

    /// @notice Set address of Chef/ChefCusinier contract responsible for minting reward tokens
    /// @param _chef Address of Chef/ChefCusinier contract
    function setChef(address _chef) external override onlyOwner {
        uint256 length;
        assembly {
            length := extcodesize(_chef)
        }
        require(length > 0, "chef not contract!");

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
