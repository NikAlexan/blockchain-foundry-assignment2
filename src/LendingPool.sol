// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SimpleERC20} from "./mocks/SimpleERC20.sol";

// Упрощённый протокол кредитования (аналог Aave/Compound).
// Один токен используется и как залог, и как кредит.
// Поток: deposit → borrow → repay → withdraw.
// Если здоровье позиции падает ниже 1 — её может ликвидировать любой.
contract LendingPool {
    error ZeroAmount();
    error ExceedsLTV();               // попытка занять больше 75% от залога
    error NoDebt();
    error InsufficientCollateral();
    error UnhealthyAfterWithdraw();   // вывод сделал бы позицию нездоровой
    error PositionHealthy();          // нельзя ликвидировать здоровую позицию
    error InsufficientPoolLiquidity();
    error InvalidPrice();

    // Данные по каждому пользователю
    struct Position {
        uint256 deposited;      // залог (в токенах)
        uint256 borrowed;       // текущий долг с накопленными процентами
        uint256 lastAccruedAt;  // timestamp последнего начисления процентов
    }

    event Deposited(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Liquidated(address indexed user, address indexed liquidator, uint256 repaidDebt, uint256 seizedCollateral);
    event PriceUpdated(uint256 newPrice);

    uint256 public constant MAX_LTV_BPS = 7500;          // максимум 75% от залога можно занять
    uint256 public constant LIQUIDATION_BONUS_BPS = 1000; // ликвидатор получает +10% к изъятому залогу
    uint256 public constant BPS = 10000;                  // базис-пойнты: 10000 = 100%
    uint256 public constant WAD = 1e18;                   // 1.0 в формате с 18 знаками (fixed-point)
    // ~10% годовых в секундах: 0.1 / (365 * 24 * 3600) ≈ 3.17e-9, умноженное на WAD
    uint256 public constant INTEREST_RATE_PER_SECOND_WAD = 3170979198;

    SimpleERC20 public immutable asset;
    uint256 public collateralPrice = WAD; // цена залога в WAD (1.0 = залог равен номиналу)
    mapping(address => Position) public positions;

    constructor(address asset_) {
        asset = SimpleERC20(asset_);
    }

    // Устанавливает цену залога (упрощённый оракул — в реальном протоколе это был бы Chainlink).
    function setCollateralPrice(uint256 newPrice) external {
        if (newPrice == 0) revert InvalidPrice();
        collateralPrice = newPrice;
        emit PriceUpdated(newPrice);
    }

    // Вносит токены как залог. Сначала начисляются проценты по текущему долгу.
    function deposit(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();

        _accrueInterest(msg.sender);
        positions[msg.sender].deposited += amount;
        require(asset.transferFrom(msg.sender, address(this), amount), "TRANSFER_FROM_FAILED");

        emit Deposited(msg.sender, amount);
    }

    // Занимает токены из пула под имеющийся залог. Лимит — 75% от стоимости залога.
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

    // Погашает долг. Если передать больше чем должен — спишется ровно долг, остаток не берётся.
    function repay(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();

        _accrueInterest(msg.sender);
        Position storage position = positions[msg.sender];
        uint256 debt = position.borrowed;
        if (debt == 0) revert NoDebt();

        uint256 paid = amount > debt ? debt : amount; // не списываем больше чем есть долг
        position.borrowed = debt - paid;
        require(asset.transferFrom(msg.sender, address(this), paid), "TRANSFER_FROM_FAILED");

        emit Repaid(msg.sender, paid);
    }

    // Выводит залог. Если есть долг — проверяет что позиция останется здоровой после вывода.
    function withdraw(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();

        _accrueInterest(msg.sender);
        Position storage position = positions[msg.sender];
        if (amount > position.deposited) revert InsufficientCollateral();

        uint256 newDeposited = position.deposited - amount;
        // healthFactor <= 1 после вывода = нельзя
        if (position.borrowed > 0 && _healthFactor(newDeposited, position.borrowed) <= WAD) revert UnhealthyAfterWithdraw();

        position.deposited = newDeposited;
        require(asset.transfer(msg.sender, amount), "TRANSFER_FAILED");

        emit Withdrawn(msg.sender, amount);
    }

    // Ликвидирует нездоровую позицию.
    // Ликвидатор погашает часть долга `user` и получает залог с бонусом +10%.
    // Пример: погашает 200 долга → получает залога на 220 (по текущей цене).
    function liquidate(address user, uint256 repayAmount) external {
        if (repayAmount == 0) revert ZeroAmount();

        _accrueInterest(user);
        Position storage position = positions[user];
        if (position.borrowed == 0) revert NoDebt();
        if (_healthFactor(position.deposited, position.borrowed) >= WAD) revert PositionHealthy();

        uint256 price = collateralPrice;
        // Сколько долга можно покрыть имеющимся залогом с учётом бонуса
        uint256 maxRepayFromCollateral = (position.deposited * price * BPS) / ((BPS + LIQUIDATION_BONUS_BPS) * WAD);
        uint256 actualRepay = repayAmount > position.borrowed ? position.borrowed : repayAmount;
        if (actualRepay > maxRepayFromCollateral) {
            actualRepay = maxRepayFromCollateral;
        }
        if (actualRepay == 0) revert InsufficientCollateral();

        // Сколько залога изымается: repay + 10% бонус, пересчитанный в токены через цену
        uint256 seizedCollateral = (actualRepay * (BPS + LIQUIDATION_BONUS_BPS) * WAD) / (price * BPS);
        if (seizedCollateral > position.deposited) {
            seizedCollateral = position.deposited;
        }

        position.borrowed -= actualRepay;
        position.deposited -= seizedCollateral;

        require(asset.transferFrom(msg.sender, address(this), actualRepay), "TRANSFER_FROM_FAILED");
        require(asset.transfer(msg.sender, seizedCollateral), "TRANSFER_FAILED"); // залог + бонус ликвидатору

        emit Liquidated(user, msg.sender, actualRepay, seizedCollateral);
    }

    // Возвращает health factor позиции с учётом накопленных процентов.
    // > 1e18 = здоровая, < 1e18 = можно ликвидировать, type(uint256).max = нет долга.
    function healthFactor(address user) external view returns (uint256 hf) {
        Position memory position = positions[user];
        uint256 accruedDebt = _debtWithInterest(position);
        hf = _healthFactor(position.deposited, accruedDebt);
    }

    // Возвращает текущий долг пользователя с накопленными процентами (read-only).
    function currentBorrowBalance(address user) external view returns (uint256) {
        return _debtWithInterest(positions[user]);
    }

    // Начисляет проценты на долг пользователя и записывает в storage.
    // Вызывается в начале каждой операции чтобы долг всегда был актуальным.
    function _accrueInterest(address user) internal {
        Position storage position = positions[user];

        if (position.lastAccruedAt == 0) {
            // Первое взаимодействие — просто фиксируем текущее время
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

        // Линейное начисление: interest = debt * rate * секунды
        uint256 interest = (debt * INTEREST_RATE_PER_SECOND_WAD * elapsed) / WAD;
        position.borrowed = debt + interest;
        position.lastAccruedAt = block.timestamp;
    }

    // Рассчитывает долг с процентами без записи в storage (для view-функций).
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

    // Максимальный займ = стоимость залога * 75%.
    // collateralPrice в WAD, поэтому делим на WAD при расчёте стоимости.
    function _maxBorrowAllowed(uint256 depositedCollateral) internal view returns (uint256) {
        uint256 collateralValue = (depositedCollateral * collateralPrice) / WAD;
        return (collateralValue * MAX_LTV_BPS) / BPS;
    }

    // healthFactor = maxBorrow / текущийДолг (в WAD).
    // Если долга нет — возвращает максимальное значение uint256.
    function _healthFactor(uint256 depositedCollateral, uint256 debt) internal view returns (uint256) {
        if (debt == 0) return type(uint256).max;

        uint256 maxBorrow = _maxBorrowAllowed(depositedCollateral);
        if (maxBorrow == 0) return 0;

        return (maxBorrow * WAD) / debt;
    }
}
