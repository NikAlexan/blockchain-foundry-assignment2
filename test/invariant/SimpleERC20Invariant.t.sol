// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {SimpleERC20} from "../../src/mocks/SimpleERC20.sol";

contract InvariantHandler is Test {
    SimpleERC20 internal token;
    address[] internal users;

    constructor(SimpleERC20 token_) {
        token = token_;
        users.push(address(0x1));
        users.push(address(0x2));
        users.push(address(0x3));

        for (uint256 i = 0; i < users.length; i++) {
            token.mint(users[i], 1_000 ether);
        }
    }

    function transferRandom(uint256 fromIdx, uint256 toIdx, uint256 amount) external {
        fromIdx = fromIdx % users.length;
        toIdx = toIdx % users.length;
        address from = users[fromIdx];
        address to = users[toIdx];
        uint256 bal = token.balanceOf(from);
        if (bal == 0) return;
        amount = amount % (bal + 1);
        vm.prank(from);
        token.transfer(to, amount);
    }

    function usersLength() external view returns (uint256) {
        return users.length;
    }

    function userAt(uint256 idx) external view returns (address) {
        return users[idx];
    }
}

contract SimpleERC20InvariantTest is Test {
    SimpleERC20 internal token;
    InvariantHandler internal handler;
    uint256 internal initialSupply;

    function setUp() external {
        token = new SimpleERC20("Mock", "MOCK");
        handler = new InvariantHandler(token);
        initialSupply = token.totalSupply();
        targetContract(address(handler));
    }

    function invariant_TotalSupplyConstant() external view {
        assertEq(token.totalSupply(), initialSupply);
    }

    function invariant_SumOfTrackedBalancesEqualsTotalSupply() external view {
        uint256 sum;
        uint256 len = handler.usersLength();
        for (uint256 i = 0; i < len; i++) {
            sum += token.balanceOf(handler.userAt(i));
        }
        assertEq(sum, token.totalSupply());
    }

    function invariant_EachUserBalanceWithinTotalSupply() external view {
        uint256 len = handler.usersLength();
        uint256 supply = token.totalSupply();
        for (uint256 i = 0; i < len; i++) {
            assertLe(token.balanceOf(handler.userAt(i)), supply);
        }
    }
}
