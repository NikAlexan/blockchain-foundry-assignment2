// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {SimpleERC20} from "../../src/mocks/SimpleERC20.sol";

contract SimpleERC20UnitTest is Test {
    SimpleERC20 internal token;
    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);
    address internal charlie = address(0xCA11);

    function setUp() external {
        token = new SimpleERC20("Mock", "MOCK");
        token.mint(alice, 1_000 ether);
    }

    function testMetadata() external view {
        assertEq(token.name(), "Mock");
        assertEq(token.symbol(), "MOCK");
        assertEq(token.decimals(), 18);
    }

    function testMintUpdatesBalanceAndSupply() external {
        token.mint(bob, 2 ether);
        assertEq(token.balanceOf(bob), 2 ether);
        assertEq(token.totalSupply(), 1_002 ether);
    }

    function testMintEmitsTransferFromZeroAddress() external {
        vm.expectEmit(true, true, true, true);
        emit SimpleERC20.Transfer(address(0), bob, 5 ether);
        token.mint(bob, 5 ether);
    }

    function testMintRevertsForZeroAddress() external {
        vm.expectRevert("ZERO_ADDRESS");
        token.mint(address(0), 1 ether);
    }

    function testApproveSetsAllowanceAndReturnsTrue() external {
        vm.prank(alice);
        bool ok = token.approve(bob, 99 ether);

        assertTrue(ok);
        assertEq(token.allowance(alice, bob), 99 ether);
    }

    function testApproveEmitsApprovalEvent() external {
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit SimpleERC20.Approval(alice, bob, 10 ether);
        token.approve(bob, 10 ether);
    }

    function testTransferMovesBalanceAndReturnsTrue() external {
        vm.prank(alice);
        bool ok = token.transfer(bob, 10 ether);

        assertTrue(ok);
        assertEq(token.balanceOf(alice), 990 ether);
        assertEq(token.balanceOf(bob), 10 ether);
    }

    function testTransferRevertsForZeroAddressRecipient() external {
        vm.prank(alice);
        vm.expectRevert("ZERO_ADDRESS");
        token.transfer(address(0), 1 ether);
    }

    function testTransferRevertsWhenInsufficientBalance() external {
        vm.prank(bob);
        vm.expectRevert("INSUFFICIENT_BALANCE");
        token.transfer(alice, 1 ether);
    }

    function testTransferFromMovesBalanceAndDecreasesAllowance() external {
        vm.prank(alice);
        token.approve(bob, 25 ether);

        vm.prank(bob);
        bool ok = token.transferFrom(alice, charlie, 10 ether);

        assertTrue(ok);
        assertEq(token.balanceOf(alice), 990 ether);
        assertEq(token.balanceOf(charlie), 10 ether);
        assertEq(token.allowance(alice, bob), 15 ether);
    }

    function testTransferFromRevertsWhenAllowanceInsufficient() external {
        vm.prank(alice);
        token.approve(bob, 1 ether);

        vm.prank(bob);
        vm.expectRevert("INSUFFICIENT_ALLOWANCE");
        token.transferFrom(alice, charlie, 2 ether);
    }

    function testTransferFromRevertsWhenBalanceInsufficient() external {
        vm.prank(alice);
        token.approve(bob, 2_000 ether);

        vm.prank(bob);
        vm.expectRevert("INSUFFICIENT_BALANCE");
        token.transferFrom(alice, charlie, 1_001 ether);
    }

    function testTransferFromRevertsForZeroFromAddress() external {
        vm.expectRevert("ZERO_ADDRESS");
        token.transferFrom(address(0), bob, 0);
    }
}
