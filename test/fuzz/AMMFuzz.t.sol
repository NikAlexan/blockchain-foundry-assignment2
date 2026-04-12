// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {AMM} from "../../src/AMM.sol";
import {SimpleERC20} from "../../src/mocks/SimpleERC20.sol";

contract AMMFuzzTest is Test {
    SimpleERC20 internal tokenA;
    SimpleERC20 internal tokenB;
    AMM internal amm;
    address internal lpProvider = address(0xAAA1);
    address internal trader = address(0xBBB2);

    function setUp() external {
        tokenA = new SimpleERC20("Token A", "TKNA");
        tokenB = new SimpleERC20("Token B", "TKNB");
        amm = new AMM(address(tokenA), address(tokenB));

        tokenA.mint(lpProvider, 2_000_000 ether);
        tokenB.mint(lpProvider, 2_000_000 ether);
        tokenA.mint(trader, 2_000_000 ether);
        tokenB.mint(trader, 2_000_000 ether);

        vm.startPrank(lpProvider);
        tokenA.approve(address(amm), type(uint256).max);
        tokenB.approve(address(amm), type(uint256).max);
        amm.addLiquidity(1_000_000 ether, 1_000_000 ether, 0);
        vm.stopPrank();

        vm.prank(trader);
        tokenA.approve(address(amm), type(uint256).max);
        vm.prank(trader);
        tokenB.approve(address(amm), type(uint256).max);
    }

    function testFuzz_SwapAToBMatchesQuote(uint256 amountIn) external {
        amountIn = bound(amountIn, 1 wei, 50_000 ether);

        uint256 reserveABefore = amm.reserveA();
        uint256 reserveBBefore = amm.reserveB();
        uint256 quote = amm.getAmountOut(amountIn, reserveABefore, reserveBBefore);

        vm.prank(trader);
        uint256 out = amm.swap(address(tokenA), amountIn, 0);

        assertEq(out, quote);
        assertEq(amm.reserveA(), reserveABefore + amountIn);
        assertEq(amm.reserveB(), reserveBBefore - out);
    }

    function testFuzz_KNonDecreaseAfterSwap(uint256 amountIn, bool swapAToB) external {
        amountIn = bound(amountIn, 1 wei, 50_000 ether);

        uint256 kBefore = amm.reserveA() * amm.reserveB();

        vm.prank(trader);
        if (swapAToB) {
            amm.swap(address(tokenA), amountIn, 0);
        } else {
            amm.swap(address(tokenB), amountIn, 0);
        }

        uint256 kAfter = amm.reserveA() * amm.reserveB();
        assertGe(kAfter, kBefore);
    }
}
