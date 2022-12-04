// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin/token/ERC20/IERC20.sol";
import "./IChef.sol";

interface ISteak is IERC20 {
    function chef() external view returns (IChef);

    function serve(address _account, uint256 _amount) external;

    function setChef(IChef _chef) external;
}
