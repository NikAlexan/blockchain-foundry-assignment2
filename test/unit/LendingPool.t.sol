// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {LendingPool} from "../../src/LendingPool.sol";
import {SimpleERC20} from "../../src/mocks/SimpleERC20.sol";

contract LendingPoolUnitTest is Test {
    SimpleERC20 internal asset;
    LendingPool internal pool;

    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);
    address internal liquidator = address(0x1A1);

    function setUp() external {
        asset = new SimpleERC20("Mock USD", "mUSD");
        pool = new LendingPool(address(asset));

        asset.mint(alice, 10_000 ether);
        asset.mint(bob, 10_000 ether);
        asset.mint(liquidator, 10_000 ether);

        vm.prank(alice);
        asset.approve(address(pool), type(uint256).max);
        vm.prank(bob);
        asset.approve(address(pool), type(uint256).max);
        vm.prank(liquidator);
        asset.approve(address(pool), type(uint256).max);
    }

    function testDepositTracksPosition() external {
        vm.prank(alice);
        pool.deposit(1_000 ether);

        (uint256 deposited, uint256 borrowed,) = pool.positions(alice);
        assertEq(deposited, 1_000 ether);
        assertEq(borrowed, 0);
        assertEq(asset.balanceOf(address(pool)), 1_000 ether);
    }

    function testWithdrawWithoutDebt() external {
        vm.prank(alice);
        pool.deposit(1_000 ether);

        vm.prank(alice);
        pool.withdraw(400 ether);

        (uint256 deposited, uint256 borrowed,) = pool.positions(alice);
        assertEq(deposited, 600 ether);
        assertEq(borrowed, 0);
        assertEq(asset.balanceOf(alice), 9_400 ether);
    }

    function testBorrowWithinLtv() external {
        vm.prank(alice);
        pool.deposit(1_000 ether);

        vm.prank(alice);
        pool.borrow(750 ether);

        (, uint256 borrowed,) = pool.positions(alice);
        assertEq(borrowed, 750 ether);
        assertEq(asset.balanceOf(alice), 9_750 ether);
    }

    function testBorrowAboveLtvReverts() external {
        vm.prank(alice);
        pool.deposit(1_000 ether);

        vm.prank(alice);
        vm.expectRevert(LendingPool.ExceedsLTV.selector);
        pool.borrow(751 ether);
    }

    function testBorrowWithZeroCollateralReverts() external {
        vm.prank(alice);
        vm.expectRevert(LendingPool.ExceedsLTV.selector);
        pool.borrow(1 ether);
    }

    function testRepayPartial() external {
        vm.startPrank(alice);
        pool.deposit(1_000 ether);
        pool.borrow(500 ether);
        pool.repay(200 ether);
        vm.stopPrank();

        (, uint256 borrowed,) = pool.positions(alice);
        assertEq(borrowed, 300 ether);
    }

    function testRepayFullCapsToDebt() external {
        vm.startPrank(alice);
        pool.deposit(1_000 ether);
        pool.borrow(500 ether);
        pool.repay(2_000 ether);
        vm.stopPrank();

        (, uint256 borrowed,) = pool.positions(alice);
        assertEq(borrowed, 0);
    }

    function testRepayWithoutDebtReverts() external {
        vm.prank(alice);
        vm.expectRevert(LendingPool.NoDebt.selector);
        pool.repay(1 ether);
    }

    function testWithdrawWithOutstandingDebtCanRevertOnHealthFactor() external {
        vm.startPrank(alice);
        pool.deposit(1_000 ether);
        pool.borrow(700 ether);
        vm.expectRevert(LendingPool.UnhealthyAfterWithdraw.selector);
        pool.withdraw(200 ether);
        vm.stopPrank();
    }

    function testInterestAccruesOverTime() external {
        vm.startPrank(alice);
        pool.deposit(1_000 ether);
        pool.borrow(500 ether);
        vm.stopPrank();

        uint256 beforeDebt = pool.currentBorrowBalance(alice);
        vm.warp(block.timestamp + 7 days);
        uint256 afterDebt = pool.currentBorrowBalance(alice);

        assertGt(afterDebt, beforeDebt);
    }

    function testLiquidationAfterPriceDrop() external {
        vm.startPrank(alice);
        pool.deposit(1_000 ether);
        pool.borrow(700 ether);
        vm.stopPrank();

        pool.setCollateralPrice(0.8 ether);
        assertLt(pool.healthFactor(alice), 1e18);

        vm.prank(liquidator);
        pool.liquidate(alice, 200 ether);

        (uint256 deposited, uint256 borrowed,) = pool.positions(alice);
        assertEq(borrowed, 500 ether);
        assertEq(deposited, 725 ether);
        assertEq(asset.balanceOf(liquidator), 10_075 ether);
    }

    function testLiquidationHealthyPositionReverts() external {
        vm.startPrank(alice);
        pool.deposit(1_000 ether);
        pool.borrow(500 ether);
        vm.stopPrank();

        vm.prank(liquidator);
        vm.expectRevert(LendingPool.PositionHealthy.selector);
        pool.liquidate(alice, 100 ether);
    }

    function testWithdrawWithDebtAllowedWhenHealthFactorAboveOne() external {
        vm.startPrank(alice);
        pool.deposit(1_000 ether);
        pool.borrow(500 ether);
        pool.withdraw(100 ether);
        vm.stopPrank();

        (uint256 deposited, uint256 borrowed,) = pool.positions(alice);
        assertEq(deposited, 900 ether);
        assertEq(borrowed, 500 ether);
        assertGt(pool.healthFactor(alice), 1e18);
    }
}
