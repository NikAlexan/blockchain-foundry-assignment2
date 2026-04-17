// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Токен-расписка для провайдеров ликвидности AMM.
// Только контракт AMM, который создал этот токен, может делать mint и burn.
contract LPToken {
    string public constant name = "AMM LP Token";
    string public constant symbol = "AMMLP";
    uint8 public constant decimals = 18;

    address public immutable amm; // адрес AMM, который задеплоил этот токен
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 amount);

    constructor() {
        // msg.sender при деплое — это AMM контракт
        amm = msg.sender;
    }

    // Выдаёт LP-токены провайдеру ликвидности при добавлении в пул.
    function mint(address to, uint256 amount) external {
        require(msg.sender == amm, "ONLY_AMM"); // только AMM может создавать токены
        require(to != address(0), "ZERO_ADDRESS");
        require(amount > 0, "ZERO_AMOUNT");
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    // Сжигает LP-токены при выводе ликвидности из пула.
    function burn(address from, uint256 amount) external {
        require(msg.sender == amm, "ONLY_AMM"); // только AMM может сжигать токены
        require(from != address(0), "ZERO_ADDRESS");
        require(amount > 0, "ZERO_AMOUNT");
        require(balanceOf[from] >= amount, "INSUFFICIENT_BALANCE");
        balanceOf[from] -= amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount); // to = address(0) — стандартный признак burn
    }
}
