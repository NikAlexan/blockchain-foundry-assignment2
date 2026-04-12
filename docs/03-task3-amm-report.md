# Task 3 Report — Constant Product AMM

## Objective
Implement a two-token AMM with constant-product pricing, LP accounting, swap fees, and slippage protection.

## What was implemented
- `src/AMM.sol`
  - `addLiquidity`
  - `removeLiquidity`
  - `swap`
  - `getAmountOut`
  - events: `LiquidityAdded`, `LiquidityRemoved`, `Swap`
- `src/LPToken.sol` for AMM-controlled LP mint/burn.
- ERC-20 pair tokens from `src/mocks/SimpleERC20.sol`.
- AMM unit and fuzz tests in:
  - `test/unit/AMM.t.sol`
  - `test/fuzz/AMMFuzz.t.sol`

## Key behavior covered
- First and subsequent liquidity providers.
- Full and partial liquidity removal.
- Swaps in both directions.
- 0.3% fee application in quote path.
- Slippage protection via minimum output checks.
- Invariant-oriented checks (`k` non-decrease expectation with fees).
- Edge-case handling for zero/invalid inputs and unsupported tokens.

## Gas profiling summary
Gas reports are generated via `forge test --gas-report`. Include final measured values from your environment in the placeholder section below.

## Evidence
### AMM unit/fuzz tests passing output
![Task 3 AMM Unit and Fuzz](../artifacts/screenshots/task3-amm-tests-gas/screen%201.png)

### AMM swap/add/remove group output
![Task 3 AMM Swap Add Remove](../artifacts/screenshots/task3-amm-tests-gas/screen%202.png)

### AMM gas report table
![Task 3 AMM Gas Report](../artifacts/screenshots/task3-amm-tests-gas/screen%203.png)

### AMM metrics table/source screenshot
![Task 3 AMM Metrics](../artifacts/screenshots/task3-amm-tests-gas/screen%204.png)
