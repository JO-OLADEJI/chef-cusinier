// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;
// // import "../src/ERC20Mock.sol";

// import "openzeppelin/token/ERC20/IERC20.sol";
// import "forge-std/Test.sol";
// import "../src/ChefCusinier.sol";
// import "../src/Steak.sol";
// import "../src/interfaces/ISteak.sol";
// import "../src/interfaces/IChefCusinier.sol";
// import "./mocks/ERC20.sol";

// contract ChefCusinierTest is Test {
//     ChefCusinier public chefCusinier;
//     IERC20 public capitalToken;
//     ISteak public steakToken;
//     uint256 public steakPerBlock = 100;

//     address public alice = address(0xa);
//     address public bob = address(0xb);
//     address public charlie = address(0xc);

//     function setUp() public {
//         Steak _steakToken = new Steak();
//         ERC20Mock _capitalToken = new ERC20Mock();

//         capitalToken = IERC20(_capitalToken);
//         steakToken = ISteak(_steakToken);

//         chefCusinier = new ChefCusinier(capitalToken, steakToken, 100);
//         steakToken.setChef(IChefCusinier(chefCusinier));

//         // give unlimited approval to ChefCusinier contract
//         vm.prank(alice);
//         capitalToken.approve(address(chefCusinier), type(uint256).max);

//         vm.prank(bob);
//         capitalToken.approve(address(chefCusinier), type(uint256).max);

//         vm.prank(charlie);
//         capitalToken.approve(address(chefCusinier), type(uint256).max);
//     }

//     function testRewards() public {
//         // ---------- BLOCK.NUMBER = 0 ----------
//         _mintCapitalTokens(alice, 100);
//         vm.prank(alice);
//         chefCusinier.deposit(100);
//         // --------------------------------------

//         skip(10);

//         // ---------- BLOCK.NUMBER = 10 ----------
//         _mintCapitalTokens(bob, 400);
//         vm.prank(bob);
//         chefCusinier.deposit(400);
//         // --------------------------------------

//         skip(5);

//         // ----------------------- BLOCK.NUMBER = 15 -----------------------
//         uint256 aliceAR_1 = 1100;
//         assertEq(chefCusinier.getPendingSteak(alice), aliceAR_1);
//         vm.prank(alice);
//         chefCusinier.claimPendingSteak();
//         assertEq(steakToken.balanceOf(alice), aliceAR_1);

//         _mintCapitalTokens(charlie, 200);
//         vm.prank(charlie);
//         chefCusinier.deposit(200);

//         assertEq(chefCusinier.getPendingSteak(alice), 0);
//         assertEq(chefCusinier.getPendingSteak(bob), 400);
//         assertEq(chefCusinier.getPendingSteak(charlie), 0);
//         // ------------------------------------------------------------------

//         skip(10);

//         // ----------------------- BLOCK.NUMBER = 25 -----------------------
//         _mintCapitalTokens(alice, 200);
//         vm.prank(alice);
//         chefCusinier.deposit(200);

//         uint256 bobAR_1 = 971;
//         assertEq(chefCusinier.getPendingSteak(bob), bobAR_1);
//         vm.prank(bob);
//         chefCusinier.claimPendingSteak();
//         assertEq(steakToken.balanceOf(bob), bobAR_1);

//         assertEq(chefCusinier.getPendingSteak(alice), 142);
//         assertEq(chefCusinier.getPendingSteak(bob), 0);
//         assertEq(chefCusinier.getPendingSteak(charlie), 285);
//         // ------------------------------------------------------------------

//         skip(15);

//         // ----------------------- BLOCK.NUMBER = 40 -----------------------
//         _mintCapitalTokens(charlie, 1_000);
//         vm.prank(charlie);
//         chefCusinier.deposit(1_000);

//         assertEq(chefCusinier.getPendingSteak(alice), 642);
//         assertEq(chefCusinier.getPendingSteak(bob), 666);
//         assertEq(chefCusinier.getPendingSteak(charlie), 619);
//         // ------------------------------------------------------------------

//         skip(20);

//         // ----------------------- BLOCK.NUMBER = 60 -----------------------
//         assertEq(chefCusinier.getPendingSteak(alice), 957);
//         assertEq(chefCusinier.getPendingSteak(bob), 1087);
//         assertEq(chefCusinier.getPendingSteak(charlie), 1882);

//         vm.prank(bob);
//         chefCusinier.withdraw(200);
//         // ------------------------------------------------------------------

//         skip(40);

//         // ----------------------- BLOCK.NUMBER = 100 -----------------------
//         uint256 aliceAR_2 = 1663;
//         assertEq(chefCusinier.getPendingSteak(alice), aliceAR_2);
//         vm.prank(alice);
//         chefCusinier.claimPendingSteak();
//         assertEq(steakToken.balanceOf(alice), aliceAR_1 + aliceAR_2);

//         uint256 bobAR_2 = 1557;
//         assertEq(chefCusinier.getPendingSteak(bob), bobAR_2);
//         vm.prank(bob);
//         chefCusinier.claimPendingSteak();
//         assertEq(steakToken.balanceOf(bob), bobAR_1 + bobAR_2);

//         vm.prank(charlie);
//         chefCusinier.withdraw(500);

//         assertEq(chefCusinier.getPendingSteak(alice), 0);
//         assertEq(chefCusinier.getPendingSteak(bob), 0);
//         assertEq(chefCusinier.getPendingSteak(charlie), 4705);
//         // ------------------------------------------------------------------

//         skip(10);

//         // ----------------------- BLOCK.NUMBER = 110 -----------------------
//         uint256 aliceAR_3 = 250;
//         assertEq(chefCusinier.getPendingSteak(alice), aliceAR_3);
//         vm.prank(alice);
//         chefCusinier.claimPendingSteak();
//         assertEq(
//             steakToken.balanceOf(alice),
//             aliceAR_1 + aliceAR_2 + aliceAR_3
//         );

//         assertEq(chefCusinier.getPendingSteak(alice), 0);
//         assertEq(chefCusinier.getPendingSteak(bob), 167);
//         assertEq(chefCusinier.getPendingSteak(charlie), 5288);

//         // ------------------------------------------------------------------

//         skip(10);

//         // ----------------------- BLOCK.NUMBER = 120 -----------------------
//         uint256 aliceAR_4 = 250;
//         assertEq(chefCusinier.getPendingSteak(alice), aliceAR_4);
//         vm.prank(alice);
//         chefCusinier.claimPendingSteak();
//         assertEq(
//             steakToken.balanceOf(alice),
//             aliceAR_1 + aliceAR_2 + aliceAR_3 + aliceAR_4
//         );

//         assertEq(chefCusinier.getPendingSteak(alice), 0);
//         assertEq(chefCusinier.getPendingSteak(bob), 333);
//         assertEq(chefCusinier.getPendingSteak(charlie), 5871);
//         // ------------------------------------------------------------------

//         skip(15);

//         // ----------------------- BLOCK.NUMBER = 135 -----------------------
//         uint256 aliceAR_5 = 375;
//         assertEq(chefCusinier.getPendingSteak(alice), aliceAR_5);
//         vm.prank(alice);
//         chefCusinier.claimPendingSteak();
//         assertEq(
//             steakToken.balanceOf(alice),
//             aliceAR_1 + aliceAR_2 + aliceAR_3 + aliceAR_4 + aliceAR_5
//         );

//         uint256 bobAR_3 = 583;
//         assertEq(chefCusinier.getPendingSteak(bob), bobAR_3);
//         vm.prank(bob);
//         chefCusinier.claimPendingSteak();
//         assertEq(steakToken.balanceOf(bob), bobAR_1 + bobAR_2 + bobAR_3);

// 		uint256 charlieAR_1 = 6746;
//         assertEq(chefCusinier.getPendingSteak(charlie), charlieAR_1);
//         vm.prank(charlie);
//         chefCusinier.claimPendingSteak();
//         assertEq(steakToken.balanceOf(charlie), charlieAR_1);

//         assertEq(chefCusinier.getPendingSteak(alice), 0);
//         assertEq(chefCusinier.getPendingSteak(bob), 0);
//         assertEq(chefCusinier.getPendingSteak(charlie), 0);

// 		assertApproxEqAbs(steakToken.totalSupply(), 135 * steakPerBlock, 5);
//         // ------------------------------------------------------------------
//     }

//     function _mintCapitalTokens(address _account, uint256 _amount) private {
//         (bool success, ) = address(capitalToken).call(
//             abi.encodeWithSignature("mint(address,uint256)", _account, _amount)
//         );
//         require(success, "mint failed");
//     }
// }
