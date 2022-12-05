// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin/token/ERC20/IERC20.sol";

/**
 *
 * @title ISteak
 * @author Joshua Oladeji <analogdev.eth>
 *
 */

interface ISteak is IERC20 {
    function chef() external view returns (address);

    function serve(address _account, uint256 _amount) external;

    function setChef(address _chef) external;
}
