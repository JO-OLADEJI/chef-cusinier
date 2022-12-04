// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor() ERC20("MockToken", "MTN") {}

    function mint(address _account, uint256 _amount) external {
        _mint(_account, _amount);
    }
}
