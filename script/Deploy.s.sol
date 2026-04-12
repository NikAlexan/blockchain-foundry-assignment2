// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {SimpleERC20} from "../src/mocks/SimpleERC20.sol";
import {AMM} from "../src/AMM.sol";
import {LendingPool} from "../src/LendingPool.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();
        SimpleERC20 tokenA = new SimpleERC20("Token A", "TKNA");
        SimpleERC20 tokenB = new SimpleERC20("Token B", "TKNB");
        new AMM(address(tokenA), address(tokenB));
        new LendingPool(address(tokenA));
        vm.stopBroadcast();
    }
}

