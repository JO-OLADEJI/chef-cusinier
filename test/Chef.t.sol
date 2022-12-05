// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin/token/ERC20/IERC20.sol";
import "forge-std/Test.sol";
import "../src/interfaces/ISteak.sol";
import "../src/interfaces/IChef.sol";
import "../src/Chef.sol";
import "../src/Steak.sol";
import "./mocks/ERC20.sol";

contract ChefTest is Test {
    Chef public chef;
    IERC20 public capitalToken;
    ISteak public steakToken;
    uint256 public steakPerSecond = 100;

    address public alice = address(0xa);
    address public bob = address(0xb);
    address public charlie = address(0xc);
    address public protocol = address(0xabc);
    uint96 public protocolShare = 5; // 5%

    function setUp() public {
        Steak _steakToken = new Steak();
        ERC20Mock _capitalToken = new ERC20Mock();

        capitalToken = IERC20(_capitalToken);
        steakToken = ISteak(_steakToken);

        chef = new Chef(capitalToken, steakToken, 100, protocol, protocolShare);
        steakToken.setChef(IChef(chef));

        // give unlimited approval to ChefCusinier contract
        vm.prank(alice);
        capitalToken.approve(address(chef), type(uint256).max);

        vm.prank(bob);
        capitalToken.approve(address(chef), type(uint256).max);

        vm.prank(charlie);
        capitalToken.approve(address(chef), type(uint256).max);
    }

    function testRewards() public {
        uint256 protocolRewards;

        // ---------- BLOCK.TIMESTAMP = 0 ----------
        _mintCapitalTokens(alice, 100);
        vm.prank(alice);
        chef.deposit(100);
        // ------------------------------------------

        skip(10);

        // ---------- BLOCK.TIMESTAMP = 10 ----------
        _mintCapitalTokens(bob, 400);
        vm.prank(bob);
        chef.deposit(400);
        // ------------------------------------------

        skip(5);

        // ----------------------- BLOCK.TIMESTAMP = 15 -----------------------
        uint256 aliceAR_1 = 1100;
        assertEq(chef.getPendingSteak(alice), aliceAR_1);
        vm.prank(alice);
        chef.claimPendingSteak();
        assertEq(steakToken.balanceOf(alice), aliceAR_1);
        protocolRewards += (aliceAR_1 * protocolShare) / 100;

        _mintCapitalTokens(charlie, 200);
        vm.prank(charlie);
        chef.deposit(200);

        assertEq(chef.getPendingSteak(alice), 0);
        assertEq(chef.getPendingSteak(bob), 400);
        assertEq(chef.getPendingSteak(charlie), 0);
        // ----------------------------------------------------------------------

        skip(10);

        // ----------------------- BLOCK.TIMESTAMP = 25 -----------------------
        _mintCapitalTokens(alice, 200);
        vm.prank(alice);
        chef.deposit(200);

        uint256 bobAR_1 = 971;
        assertEq(chef.getPendingSteak(bob), bobAR_1);
        vm.prank(bob);
        chef.claimPendingSteak();
        assertEq(steakToken.balanceOf(bob), bobAR_1);
        protocolRewards += (bobAR_1 * protocolShare) / 100;

        assertEq(chef.getPendingSteak(alice), 142);
        assertEq(chef.getPendingSteak(bob), 0);
        assertEq(chef.getPendingSteak(charlie), 285);
        // ----------------------------------------------------------------------

        skip(15);

        // ----------------------- BLOCK.TIMESTAMP = 40 -----------------------
        _mintCapitalTokens(charlie, 1_000);
        vm.prank(charlie);
        chef.deposit(1_000);

        assertEq(chef.getPendingSteak(alice), 642);
        assertEq(chef.getPendingSteak(bob), 666);
        assertEq(chef.getPendingSteak(charlie), 619);
        // ----------------------------------------------------------------------

        skip(20);

        // ----------------------- BLOCK.TIMESTAMP = 60 -----------------------
        assertEq(chef.getPendingSteak(alice), 957);
        assertEq(chef.getPendingSteak(bob), 1087);
        assertEq(chef.getPendingSteak(charlie), 1882);

        vm.prank(bob);
        chef.withdraw(200);
        // ----------------------------------------------------------------------

        skip(40);

        // ----------------------- BLOCK.TIMESTAMP = 100 -----------------------
        uint256 aliceAR_2 = 1663;
        assertEq(chef.getPendingSteak(alice), aliceAR_2);
        vm.prank(alice);
        chef.claimPendingSteak();
        assertEq(steakToken.balanceOf(alice), aliceAR_1 + aliceAR_2);
        protocolRewards += (aliceAR_2 * protocolShare) / 100;

        uint256 bobAR_2 = 1557;
        assertEq(chef.getPendingSteak(bob), bobAR_2);
        vm.prank(bob);
        chef.claimPendingSteak();
        assertEq(steakToken.balanceOf(bob), bobAR_1 + bobAR_2);
        protocolRewards += (bobAR_2 * protocolShare) / 100;

        vm.prank(charlie);
        chef.withdraw(500);

        assertEq(chef.getPendingSteak(alice), 0);
        assertEq(chef.getPendingSteak(bob), 0);
        assertEq(chef.getPendingSteak(charlie), 4705);
        // ----------------------------------------------------------------------

        skip(10);

        // ----------------------- BLOCK.TIMESTAMP = 110 -----------------------
        uint256 aliceAR_3 = 250;
        assertEq(chef.getPendingSteak(alice), aliceAR_3);
        vm.prank(alice);
        chef.claimPendingSteak();
        assertEq(
            steakToken.balanceOf(alice),
            aliceAR_1 + aliceAR_2 + aliceAR_3
        );
        protocolRewards += (aliceAR_3 * protocolShare) / 100;

        assertEq(chef.getPendingSteak(alice), 0);
        assertEq(chef.getPendingSteak(bob), 167);
        assertEq(chef.getPendingSteak(charlie), 5288);

        // ----------------------------------------------------------------------

        skip(10);

        // ----------------------- BLOCK.TIMESTAMP = 120 -----------------------
        uint256 aliceAR_4 = 250;
        assertEq(chef.getPendingSteak(alice), aliceAR_4);
        vm.prank(alice);
        chef.claimPendingSteak();
        assertEq(
            steakToken.balanceOf(alice),
            aliceAR_1 + aliceAR_2 + aliceAR_3 + aliceAR_4
        );
        protocolRewards += (aliceAR_4 * protocolShare) / 100;

        assertEq(chef.getPendingSteak(alice), 0);
        assertEq(chef.getPendingSteak(bob), 333);
        assertEq(chef.getPendingSteak(charlie), 5871);
        // ----------------------------------------------------------------------

        skip(15);

        // ----------------------- BLOCK.TIMESTAMP = 135 -----------------------
        uint256 aliceAR_5 = 375;
        assertEq(chef.getPendingSteak(alice), aliceAR_5);
        vm.prank(alice);
        chef.claimPendingSteak();
        assertEq(
            steakToken.balanceOf(alice),
            aliceAR_1 + aliceAR_2 + aliceAR_3 + aliceAR_4 + aliceAR_5
        );
        protocolRewards += (aliceAR_5 * protocolShare) / 100;

        uint256 bobAR_3 = 583;
        assertEq(chef.getPendingSteak(bob), bobAR_3);
        vm.prank(bob);
        chef.claimPendingSteak();
        assertEq(steakToken.balanceOf(bob), bobAR_1 + bobAR_2 + bobAR_3);
        protocolRewards += (bobAR_3 * protocolShare) / 100;

        uint256 charlieAR_1 = 6746;
        assertEq(chef.getPendingSteak(charlie), charlieAR_1);
        vm.prank(charlie);
        chef.claimPendingSteak();
        assertEq(steakToken.balanceOf(charlie), charlieAR_1);
        protocolRewards += (charlieAR_1 * protocolShare) / 100;

        assertEq(chef.getPendingSteak(alice), 0);
        assertEq(chef.getPendingSteak(bob), 0);
        assertEq(chef.getPendingSteak(charlie), 0);
        assertEq(steakToken.balanceOf(protocol), protocolRewards);

        assertApproxEqAbs(
            steakToken.totalSupply(),
            (135 * steakPerSecond) + protocolRewards,
            5
        );
        // ----------------------------------------------------------------------
    }

    function _mintCapitalTokens(address _account, uint256 _amount) private {
        (bool success, ) = address(capitalToken).call(
            abi.encodeWithSignature("mint(address,uint256)", _account, _amount)
        );
        require(success, "mint failed");
    }
}
