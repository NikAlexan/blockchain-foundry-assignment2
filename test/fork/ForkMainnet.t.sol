// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

interface IERC20Like {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

interface IUniswapV2Router02Like {
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

contract ForkMainnetTest is Test {
    address internal constant UNISWAP_V2_ROUTER_02 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint256 internal constant FORK_BLOCK = 19_000_000;

    function setUp() external {
        string memory rpc = vm.envString("MAINNET_RPC_URL");
        vm.createSelectFork(rpc, FORK_BLOCK);
    }

    function testFork_ReadUSDC_TotalSupply() external {
        uint256 supply = IERC20Like(USDC).totalSupply();
        assertEq(block.number, FORK_BLOCK);
        assertGt(supply, 0);
    }

    function testFork_UniswapV2SwapExactETHForUSDC() external {
        address trader = makeAddr("trader");
        vm.deal(trader, 1 ether);

        uint256 beforeBalance = IERC20Like(USDC).balanceOf(trader);

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = USDC;

        vm.prank(trader);
        uint256[] memory amounts = IUniswapV2Router02Like(UNISWAP_V2_ROUTER_02).swapExactETHForTokens{value: 0.1 ether}(
            1,
            path,
            trader,
            block.timestamp + 15 minutes
        );

        uint256 afterBalance = IERC20Like(USDC).balanceOf(trader);

        assertEq(amounts.length, 2);
        assertGt(amounts[0], 0);
        assertGt(amounts[1], 0);
        assertGt(afterBalance, beforeBalance);
    }

    function testFork_RollFork_AdvancesSnapshotBlock() external {
        vm.rollFork(FORK_BLOCK + 5);
        assertEq(block.number, FORK_BLOCK + 5);
    }
}
