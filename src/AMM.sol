// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {LPToken} from "./LPToken.sol";
import {SimpleERC20} from "./mocks/SimpleERC20.sol";

// Автоматический маркет-мейкер по модели Uniswap V2.
// Цена определяется формулой постоянного произведения: reserveA * reserveB = k.
// При свопе k не уменьшается — комиссия 0.3% остаётся в пуле и увеличивает k.
contract AMM {
    error InvalidToken();
    error InvalidAmount();
    error InvalidRatio();               // нарушено соотношение токенов при добавлении ликвидности
    error InsufficientLiquidity();
    error InsufficientLiquidityMinted();
    error InsufficientLiquidityBurned();
    error SlippageExceeded();           // фактический выход меньше минимально допустимого

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpMinted);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpBurned);
    event Swap(address indexed trader, address indexed tokenIn, uint256 amountIn, uint256 amountOut);

    // Комиссия 0.3%: умножаем входную сумму на 997/1000 перед расчётом выхода.
    uint256 private constant FEE_NUMERATOR = 997;
    uint256 private constant FEE_DENOMINATOR = 1000;

    SimpleERC20 public immutable tokenA;
    SimpleERC20 public immutable tokenB;
    LPToken public immutable lpToken; // токен-расписка для провайдеров ликвидности

    uint256 public reserveA; // сколько tokenA сейчас в пуле
    uint256 public reserveB; // сколько tokenB сейчас в пуле

    constructor(address tokenA_, address tokenB_) {
        if (tokenA_ == address(0) || tokenB_ == address(0) || tokenA_ == tokenB_) revert InvalidToken();
        tokenA = SimpleERC20(tokenA_);
        tokenB = SimpleERC20(tokenB_);
        lpToken = new LPToken(); // AMM сам деплоит свой LP-токен
    }

    // Добавляет ликвидность в пул и выдаёт LP-токены.
    // minLpOut — защита от slippage: если выйдет меньше, транзакция откатится.
    function addLiquidity(uint256 amountA, uint256 amountB, uint256 minLpOut) external returns (uint256 lpOut) {
        if (amountA == 0 || amountB == 0) revert InvalidAmount();

        uint256 _reserveA = reserveA;
        uint256 _reserveB = reserveB;
        uint256 totalSupply = lpToken.totalSupply();

        if (_reserveA == 0 && _reserveB == 0) {
            // Первый провайдер: LP = sqrt(amountA * amountB).
            // Геометрическое среднее делает количество LP независимым от начального соотношения цен.
            lpOut = _sqrt(amountA * amountB);
            if (lpOut == 0) revert InsufficientLiquidityMinted();
        } else {
            // Последующие провайдеры: соотношение токенов должно совпадать с текущим в пуле.
            // Иначе провайдер мог бы изменить цену одним лишь добавлением ликвидности.
            if (_reserveA == 0 || _reserveB == 0) revert InsufficientLiquidity();
            if (amountA * _reserveB != amountB * _reserveA) revert InvalidRatio();

            // LP пропорционально доле от текущих резервов; берём минимум из двух расчётов.
            uint256 lpOutA = amountA * totalSupply / _reserveA;
            uint256 lpOutB = amountB * totalSupply / _reserveB;
            lpOut = _min(lpOutA, lpOutB);
            if (lpOut == 0) revert InsufficientLiquidityMinted();
        }

        if (lpOut < minLpOut) revert SlippageExceeded();

        _safeTransferFrom(tokenA, msg.sender, address(this), amountA);
        _safeTransferFrom(tokenB, msg.sender, address(this), amountB);

        reserveA = _reserveA + amountA;
        reserveB = _reserveB + amountB;

        lpToken.mint(msg.sender, lpOut);
        emit LiquidityAdded(msg.sender, amountA, amountB, lpOut);
    }

    // Сжигает LP-токены и возвращает пропорциональную долю обоих токенов из пула.
    // minAmountA / minAmountB — защита от slippage.
    function removeLiquidity(uint256 lpAmount, uint256 minAmountA, uint256 minAmountB)
        external
        returns (uint256 amountA, uint256 amountB)
    {
        if (lpAmount == 0) revert InvalidAmount();

        uint256 totalSupply = lpToken.totalSupply();
        if (totalSupply == 0) revert InsufficientLiquidity();

        // Доля = lpAmount / totalSupply; возвращаем ту же долю от каждого резерва.
        amountA = lpAmount * reserveA / totalSupply;
        amountB = lpAmount * reserveB / totalSupply;

        if (amountA == 0 || amountB == 0) revert InsufficientLiquidityBurned();
        if (amountA < minAmountA || amountB < minAmountB) revert SlippageExceeded();

        lpToken.burn(msg.sender, lpAmount);

        reserveA -= amountA;
        reserveB -= amountB;

        _safeTransfer(tokenA, msg.sender, amountA);
        _safeTransfer(tokenB, msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB, lpAmount);
    }

    // Обменивает `amountIn` токена `tokenIn` на другой токен пула.
    // minAmountOut — защита от slippage: если рынок сдвинулся пока летела транзакция,
    // и выход меньше минимума, транзакция откатится.
    function swap(address tokenIn, uint256 amountIn, uint256 minAmountOut) external returns (uint256 amountOut) {
        if (amountIn == 0) revert InvalidAmount();

        // Определяем направление свопа
        bool isAToB;
        if (tokenIn == address(tokenA)) {
            isAToB = true;
        } else if (tokenIn == address(tokenB)) {
            isAToB = false;
        } else {
            revert InvalidToken();
        }

        uint256 reserveIn = isAToB ? reserveA : reserveB;
        uint256 reserveOut = isAToB ? reserveB : reserveA;
        amountOut = getAmountOut(amountIn, reserveIn, reserveOut);

        if (amountOut < minAmountOut) revert SlippageExceeded();

        if (isAToB) {
            _safeTransferFrom(tokenA, msg.sender, address(this), amountIn);
            _safeTransfer(tokenB, msg.sender, amountOut);
            reserveA = reserveIn + amountIn;
            reserveB = reserveOut - amountOut;
        } else {
            _safeTransferFrom(tokenB, msg.sender, address(this), amountIn);
            _safeTransfer(tokenA, msg.sender, amountOut);
            reserveB = reserveIn + amountIn;
            reserveA = reserveOut - amountOut;
        }

        emit Swap(msg.sender, tokenIn, amountIn, amountOut);
    }

    // Рассчитывает сколько токенов получишь при свопе с учётом комиссии 0.3%.
    // Формула: amountOut = (amountIn * 997 * reserveOut) / (reserveIn * 1000 + amountIn * 997)
    // Выводится из x * y = k при условии что реальный вход = amountIn * 0.997.
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256) {
        if (amountIn == 0) revert InvalidAmount();
        if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();

        uint256 amountInWithFee = amountIn * FEE_NUMERATOR; // вычитаем 0.3% комиссии
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * FEE_DENOMINATOR + amountInWithFee;
        return numerator / denominator;
    }

    // Обёртки над transfer/transferFrom — проверяют возвращаемое значение bool.
    function _safeTransfer(SimpleERC20 token, address to, uint256 amount) internal {
        bool ok = token.transfer(to, amount);
        require(ok, "TRANSFER_FAILED");
    }

    function _safeTransferFrom(SimpleERC20 token, address from, address to, uint256 amount) internal {
        bool ok = token.transferFrom(from, to, amount);
        require(ok, "TRANSFER_FROM_FAILED");
    }

    function _min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    // Целочисленный квадратный корень методом Ньютона.
    function _sqrt(uint256 y) private pure returns (uint256 z) {
        if (y == 0) return 0;
        if (y <= 3) return 1;

        z = y;
        uint256 x = y / 2 + 1;
        while (x < z) {
            z = x;
            x = (y / x + x) / 2;
        }
    }
}
