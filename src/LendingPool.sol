// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SimpleERC20} from "./mocks/SimpleERC20.sol";

contract LendingPool {
    error ZeroAmount();
    error ExceedsLTV();
    error NoDebt();
    error InsufficientCollateral();
    error UnhealthyAfterWithdraw();
    error PositionHealthy();
    error InsufficientPoolLiquidity();
    error InvalidPrice();

    struct Position {
        uint256 deposited;
        uint256 borrowed;
        uint256 lastAccruedAt;
    }

    event Deposited(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Liquidated(address indexed user, address indexed liquidator, uint256 repaidDebt, uint256 seizedCollateral);
    event PriceUpdated(uint256 newPrice);

    uint256 public constant MAX_LTV_BPS = 7500;
    uint256 public constant LIQUIDATION_BONUS_BPS = 1000;
    uint256 public constant BPS = 10000;
    uint256 public constant WAD = 1e18;
    uint256 public constant INTEREST_RATE_PER_SECOND_WAD = 3170979198; // ~10% APR

    SimpleERC20 public immutable asset;
    uint256 public collateralPrice = WAD;
    mapping(address => Position) public positions;

    constructor(address asset_) {
        asset = SimpleERC20(asset_);
    }

    function setCollateralPrice(uint256 newPrice) external {
        if (newPrice == 0) revert InvalidPrice();
        collateralPrice = newPrice;
        emit PriceUpdated(newPrice);
    }

    function deposit(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();

        _accrueInterest(msg.sender);
        positions[msg.sender].deposited += amount;
        require(asset.transferFrom(msg.sender, address(this), amount), "TRANSFER_FROM_FAILED");

        emit Deposited(msg.sender, amount);
    }

    function borrow(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();

        _accrueInterest(msg.sender);
        Position storage position = positions[msg.sender];

        uint256 newBorrowed = position.borrowed + amount;
        if (newBorrowed > _maxBorrowAllowed(position.deposited)) revert ExceedsLTV();
        if (asset.balanceOf(address(this)) < amount) revert InsufficientPoolLiquidity();

        position.borrowed = newBorrowed;
        require(asset.transfer(msg.sender, amount), "TRANSFER_FAILED");

        emit Borrowed(msg.sender, amount);
    }

    function repay(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();

        _accrueInterest(msg.sender);
        Position storage position = positions[msg.sender];
        uint256 debt = position.borrowed;
        if (debt == 0) revert NoDebt();

        uint256 paid = amount > debt ? debt : amount;
        position.borrowed = debt - paid;
        require(asset.transferFrom(msg.sender, address(this), paid), "TRANSFER_FROM_FAILED");

        emit Repaid(msg.sender, paid);
    }

    function withdraw(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();

        _accrueInterest(msg.sender);
        Position storage position = positions[msg.sender];
        if (amount > position.deposited) revert InsufficientCollateral();

        uint256 newDeposited = position.deposited - amount;
        if (position.borrowed > 0 && _healthFactor(newDeposited, position.borrowed) <= WAD) revert UnhealthyAfterWithdraw();

        position.deposited = newDeposited;
        require(asset.transfer(msg.sender, amount), "TRANSFER_FAILED");

        emit Withdrawn(msg.sender, amount);
    }

    function liquidate(address user, uint256 repayAmount) external {
        if (repayAmount == 0) revert ZeroAmount();

        _accrueInterest(user);
        Position storage position = positions[user];
        if (position.borrowed == 0) revert NoDebt();
        if (_healthFactor(position.deposited, position.borrowed) >= WAD) revert PositionHealthy();

        uint256 price = collateralPrice;
        uint256 maxRepayFromCollateral = (position.deposited * price * BPS) / ((BPS + LIQUIDATION_BONUS_BPS) * WAD);
        uint256 actualRepay = repayAmount > position.borrowed ? position.borrowed : repayAmount;
        if (actualRepay > maxRepayFromCollateral) {
            actualRepay = maxRepayFromCollateral;
        }
        if (actualRepay == 0) revert InsufficientCollateral();

        uint256 seizedCollateral = (actualRepay * (BPS + LIQUIDATION_BONUS_BPS) * WAD) / (price * BPS);
        if (seizedCollateral > position.deposited) {
            seizedCollateral = position.deposited;
        }

        position.borrowed -= actualRepay;
        position.deposited -= seizedCollateral;

        require(asset.transferFrom(msg.sender, address(this), actualRepay), "TRANSFER_FROM_FAILED");
        require(asset.transfer(msg.sender, seizedCollateral), "TRANSFER_FAILED");

        emit Liquidated(user, msg.sender, actualRepay, seizedCollateral);
    }

    function healthFactor(address user) external view returns (uint256 hf) {
        Position memory position = positions[user];
        uint256 accruedDebt = _debtWithInterest(position);
        hf = _healthFactor(position.deposited, accruedDebt);
    }

    function currentBorrowBalance(address user) external view returns (uint256) {
        return _debtWithInterest(positions[user]);
    }

    function _accrueInterest(address user) internal {
        Position storage position = positions[user];

        if (position.lastAccruedAt == 0) {
            position.lastAccruedAt = block.timestamp;
            return;
        }

        uint256 debt = position.borrowed;
        if (debt == 0) {
            position.lastAccruedAt = block.timestamp;
            return;
        }

        uint256 elapsed = block.timestamp - position.lastAccruedAt;
        if (elapsed == 0) {
            return;
        }

        uint256 interest = (debt * INTEREST_RATE_PER_SECOND_WAD * elapsed) / WAD;
        position.borrowed = debt + interest;
        position.lastAccruedAt = block.timestamp;
    }

    function _debtWithInterest(Position memory position) internal view returns (uint256) {
        uint256 debt = position.borrowed;
        if (debt == 0) {
            return 0;
        }
        if (position.lastAccruedAt == 0 || position.lastAccruedAt >= block.timestamp) {
            return debt;
        }

        uint256 elapsed = block.timestamp - position.lastAccruedAt;
        uint256 interest = (debt * INTEREST_RATE_PER_SECOND_WAD * elapsed) / WAD;
        return debt + interest;
    }

    function _maxBorrowAllowed(uint256 depositedCollateral) internal view returns (uint256) {
        uint256 collateralValue = (depositedCollateral * collateralPrice) / WAD;
        return (collateralValue * MAX_LTV_BPS) / BPS;
    }

    function _healthFactor(uint256 depositedCollateral, uint256 debt) internal view returns (uint256) {
        if (debt == 0) return type(uint256).max;

        uint256 maxBorrow = _maxBorrowAllowed(depositedCollateral);
        if (maxBorrow == 0) return 0;

        return (maxBorrow * WAD) / debt;
    }
}
