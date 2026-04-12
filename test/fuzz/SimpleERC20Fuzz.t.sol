// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {SimpleERC20} from "../../src/mocks/SimpleERC20.sol";

contract SimpleERC20FuzzTest is Test {
    SimpleERC20 internal token;
    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    function setUp() external {
        token = new SimpleERC20("Mock", "MOCK");
        token.mint(alice, 1_000_000 ether);
    }

    function testFuzz_Transfer(uint256 amount) external {
        uint256 aliceBefore = token.balanceOf(alice);
        uint256 bobBefore = token.balanceOf(bob);
        uint256 supplyBefore = token.totalSupply();
        amount = bound(amount, 0, token.balanceOf(alice));
        vm.prank(alice);
        token.transfer(bob, amount);
        assertEq(token.balanceOf(alice), aliceBefore - amount);
        assertEq(token.balanceOf(bob), bobBefore + amount);
        assertEq(token.totalSupply(), supplyBefore);
    }

    function testFuzz_TransferToSelfKeepsBalance(uint256 amount) external {
        uint256 aliceBefore = token.balanceOf(alice);
        amount = bound(amount, 0, aliceBefore);
        vm.prank(alice);
        token.transfer(alice, amount);
        assertEq(token.balanceOf(alice), aliceBefore);
    }

    function testFuzz_TransferRevertsWhenAmountExceedsBalance(uint256 amount) external {
        amount = bound(amount, token.balanceOf(bob) + 1, type(uint256).max);
        vm.prank(bob);
        vm.expectRevert("INSUFFICIENT_BALANCE");
        token.transfer(alice, amount);
    }
}
