// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract LPToken {
    string public constant name = "AMM LP Token";
    string public constant symbol = "AMMLP";
    uint8 public constant decimals = 18;
    address public immutable amm;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 amount);

    constructor() {
        amm = msg.sender;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == amm, "ONLY_AMM");
        require(to != address(0), "ZERO_ADDRESS");
        require(amount > 0, "ZERO_AMOUNT");
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function burn(address from, uint256 amount) external {
        require(msg.sender == amm, "ONLY_AMM");
        require(from != address(0), "ZERO_ADDRESS");
        require(amount > 0, "ZERO_AMOUNT");
        require(balanceOf[from] >= amount, "INSUFFICIENT_BALANCE");
        balanceOf[from] -= amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }
}
