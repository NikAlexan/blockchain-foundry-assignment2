// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {AMM} from "../../src/AMM.sol";
import {LPToken} from "../../src/LPToken.sol";
import {SimpleERC20} from "../../src/mocks/SimpleERC20.sol";

contract AMMUnitTest is Test {
    SimpleERC20 internal tokenA;
    SimpleERC20 internal tokenB;
    AMM internal amm;
    LPToken internal lp;

    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);
    address internal trader = address(0xC0FFEE);

    function setUp() external {
        tokenA = new SimpleERC20("Token A", "TKNA");
        tokenB = new SimpleERC20("Token B", "TKNB");
        amm = new AMM(address(tokenA), address(tokenB));
        lp = amm.lpToken();

        tokenA.mint(alice, 10_000 ether);
        tokenB.mint(alice, 10_000 ether);
        tokenA.mint(bob, 10_000 ether);
        tokenB.mint(bob, 10_000 ether);
        tokenA.mint(trader, 10_000 ether);
        tokenB.mint(trader, 10_000 ether);

        vm.prank(alice);
        tokenA.approve(address(amm), type(uint256).max);
        vm.prank(alice);
        tokenB.approve(address(amm), type(uint256).max);

        vm.prank(bob);
        tokenA.approve(address(amm), type(uint256).max);
        vm.prank(bob);
        tokenB.approve(address(amm), type(uint256).max);

        vm.prank(trader);
        tokenA.approve(address(amm), type(uint256).max);
        vm.prank(trader);
        tokenB.approve(address(amm), type(uint256).max);
    }

    function testAddLiquidityFirstProviderMintsSqrt() external {
        uint256 amountA = 1_000 ether;
        uint256 amountB = 400 ether;

        vm.prank(alice);
        uint256 lpOut = amm.addLiquidity(amountA, amountB, 0);

        assertEq(lpOut, _sqrt(amountA * amountB));
        assertEq(lp.balanceOf(alice), lpOut);
        assertEq(lp.totalSupply(), lpOut);
        assertEq(amm.reserveA(), amountA);
        assertEq(amm.reserveB(), amountB);
    }

    function testAddLiquidityFirstProviderEmitsEvent() external {
        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit AMM.LiquidityAdded(alice, 1_000 ether, 1_000 ether, 1_000 ether);
        amm.addLiquidity(1_000 ether, 1_000 ether, 0);
    }

    function testAddLiquidityRevertsOnZeroAmount() external {
        vm.prank(alice);
        vm.expectRevert(AMM.InvalidAmount.selector);
        amm.addLiquidity(0, 1 ether, 0);
    }

    function testAddLiquiditySubsequentRequiresProportionalAmounts() external {
        vm.prank(alice);
        amm.addLiquidity(1_000 ether, 1_000 ether, 0);

        vm.prank(bob);
        vm.expectRevert(AMM.InvalidRatio.selector);
        amm.addLiquidity(200 ether, 150 ether, 0);
    }

    function testAddLiquiditySubsequentMintsProportionalLP() external {
        vm.startPrank(alice);
        amm.addLiquidity(1_000 ether, 1_000 ether, 0);
        vm.stopPrank();

        vm.prank(bob);
        uint256 lpOut = amm.addLiquidity(100 ether, 100 ether, 0);

        assertEq(lpOut, 100 ether);
        assertEq(lp.balanceOf(bob), 100 ether);
        assertEq(lp.totalSupply(), 1_100 ether);
        assertEq(amm.reserveA(), 1_100 ether);
        assertEq(amm.reserveB(), 1_100 ether);
    }

    function testAddLiquidityRevertsOnMinLpSlippage() external {
        vm.prank(alice);
        vm.expectRevert(AMM.SlippageExceeded.selector);
        amm.addLiquidity(100 ether, 100 ether, 101 ether);
    }

    function testRemoveLiquidityPartial() external {
        vm.prank(alice);
        amm.addLiquidity(1_000 ether, 1_000 ether, 0);

        vm.prank(alice);
        (uint256 amountA, uint256 amountB) = amm.removeLiquidity(500 ether, 0, 0);

        assertEq(amountA, 500 ether);
        assertEq(amountB, 500 ether);
        assertEq(amm.reserveA(), 500 ether);
        assertEq(amm.reserveB(), 500 ether);
        assertEq(lp.balanceOf(alice), 500 ether);
    }

    function testRemoveLiquidityFull() external {
        vm.prank(alice);
        amm.addLiquidity(1_000 ether, 1_000 ether, 0);

        uint256 lpBalance = lp.balanceOf(alice);
        vm.prank(alice);
        (uint256 amountA, uint256 amountB) = amm.removeLiquidity(lpBalance, 0, 0);

        assertEq(amountA, 1_000 ether);
        assertEq(amountB, 1_000 ether);
        assertEq(amm.reserveA(), 0);
        assertEq(amm.reserveB(), 0);
        assertEq(lp.totalSupply(), 0);
    }

    function testRemoveLiquidityRevertsOnZeroLPAmount() external {
        vm.prank(alice);
        vm.expectRevert(AMM.InvalidAmount.selector);
        amm.removeLiquidity(0, 0, 0);
    }

    function testRemoveLiquidityRevertsOnMinAmountSlippage() external {
        vm.prank(alice);
        amm.addLiquidity(1_000 ether, 1_000 ether, 0);

        vm.prank(alice);
        vm.expectRevert(AMM.SlippageExceeded.selector);
        amm.removeLiquidity(100 ether, 101 ether, 100 ether);
    }

    function testSwapAToB() external {
        vm.prank(alice);
        amm.addLiquidity(1_000 ether, 1_000 ether, 0);

        uint256 expectedOut = amm.getAmountOut(100 ether, amm.reserveA(), amm.reserveB());

        vm.prank(trader);
        uint256 amountOut = amm.swap(address(tokenA), 100 ether, 0);

        assertEq(amountOut, expectedOut);
        assertEq(amm.reserveA(), 1_100 ether);
        assertEq(amm.reserveB(), 1_000 ether - expectedOut);
    }

    function testSwapBToA() external {
        vm.prank(alice);
        amm.addLiquidity(1_000 ether, 1_000 ether, 0);

        uint256 expectedOut = amm.getAmountOut(100 ether, amm.reserveB(), amm.reserveA());

        vm.prank(trader);
        uint256 amountOut = amm.swap(address(tokenB), 100 ether, 0);

        assertEq(amountOut, expectedOut);
        assertEq(amm.reserveB(), 1_100 ether);
        assertEq(amm.reserveA(), 1_000 ether - expectedOut);
    }

    function testSwapEmitsEvent() external {
        vm.prank(alice);
        amm.addLiquidity(1_000 ether, 1_000 ether, 0);

        uint256 out = amm.getAmountOut(50 ether, amm.reserveA(), amm.reserveB());

        vm.prank(trader);
        vm.expectEmit(true, true, false, true);
        emit AMM.Swap(trader, address(tokenA), 50 ether, out);
        amm.swap(address(tokenA), 50 ether, 0);
    }

    function testSwapRevertsForUnsupportedToken() external {
        SimpleERC20 rogue = new SimpleERC20("Rogue", "RG");
        vm.prank(trader);
        vm.expectRevert(AMM.InvalidToken.selector);
        amm.swap(address(rogue), 1 ether, 0);
    }

    function testSwapRevertsForSlippage() external {
        vm.prank(alice);
        amm.addLiquidity(1_000 ether, 1_000 ether, 0);

        uint256 quote = amm.getAmountOut(100 ether, amm.reserveA(), amm.reserveB());
        vm.prank(trader);
        vm.expectRevert(AMM.SlippageExceeded.selector);
        amm.swap(address(tokenA), 100 ether, quote + 1);
    }

    function testInvariantKNonDecreaseAfterSwapWithFee() external {
        vm.prank(alice);
        amm.addLiquidity(10_000 ether, 10_000 ether, 0);

        uint256 kBefore = amm.reserveA() * amm.reserveB();

        vm.prank(trader);
        amm.swap(address(tokenA), 1_000 ether, 0);

        uint256 kAfter = amm.reserveA() * amm.reserveB();
        assertGe(kAfter, kBefore);
    }

    function testLargeSwapPriceImpact() external {
        vm.prank(alice);
        amm.addLiquidity(1_000 ether, 1_000 ether, 0);

        vm.prank(trader);
        uint256 out = amm.swap(address(tokenA), 900 ether, 0);

        assertLt(out, 900 ether);
        assertLt(out, 800 ether);
    }

    function testGetAmountOutFormula() external view {
        uint256 amountIn = 100 ether;
        uint256 reserveIn = 1_000 ether;
        uint256 reserveOut = 2_000 ether;

        uint256 expected = (amountIn * 997 * reserveOut) / (reserveIn * 1000 + amountIn * 997);
        uint256 out = amm.getAmountOut(amountIn, reserveIn, reserveOut);
        assertEq(out, expected);
    }

    function _sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y == 0) return 0;
        if (y <= 3) return 1;

        z = y;
        uint256 x = y / 2 + 1;
        while (x < z) {
            z = x;
            x = (y / x + x) / 2;
        }
    }
}
