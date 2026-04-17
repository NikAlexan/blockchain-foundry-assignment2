// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Минимальный ERC-20 токен для тестов.
// В отличие от production-токенов, mint публичный — любой может создать токены.
contract SimpleERC20 {
    string public name;
    string public symbol;
    uint8 public immutable decimals = 18; // стандартное количество знаков после запятой (как у ETH)
    uint256 public totalSupply;           // общее количество токенов в обращении

    // балансы каждого адреса
    mapping(address => uint256) public balanceOf;
    // allowance[владелец][трейдер] = сколько трейдер может потратить от имени владельца
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    // Создаёт новые токены и зачисляет на адрес `to`.
    // from = address(0) в событии Transfer — стандартный признак mint.
    function mint(address to, uint256 amount) external {
        require(to != address(0), "ZERO_ADDRESS");
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    // Разрешает `spender` тратить до `amount` токенов от твоего имени.
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // Переводит токены от отправителя транзакции.
    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    // Переводит токены от `from` (нужен предварительный approve).
    // Уменьшает allowance на потраченную сумму.
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        require(allowed >= amount, "INSUFFICIENT_ALLOWANCE");
        allowance[from][msg.sender] = allowed - amount;
        emit Approval(from, msg.sender, allowance[from][msg.sender]);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ZERO_ADDRESS");
        require(to != address(0), "ZERO_ADDRESS");
        require(balanceOf[from] >= amount, "INSUFFICIENT_BALANCE");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }
}
