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

## Evidence placeholders
- `[INSERT SCREENSHOT: AMM unit/fuzz tests passing output]`
- `[INSERT SCREENSHOT: AMM swap/add/remove test group output]`
- `[INSERT SCREENSHOT: AMM gas report table]`
- `[INSERT METRIC TABLE: AMM operation gas numbers from your final run]`

## Commands to capture each screenshot
Run from project root:

```bash
cd Project
export PATH="$HOME/.foundry/bin:$PATH"
mkdir -p artifacts/logs/forge
```

1. **AMM unit + fuzz passing output**
```bash
(forge test --match-path test/unit/AMM.t.sol -vv && forge test --match-path test/fuzz/AMMFuzz.t.sol -vv) | tee artifacts/logs/forge/task3-amm-unit-fuzz.log
```

2. **Swap/add/remove group output**
```bash
forge test --match-path test/unit/AMM.t.sol --match-test "test(AddLiquidity|RemoveLiquidity|Swap).*" -vv | tee artifacts/logs/forge/task3-amm-groups.log
```

3. **AMM gas report table**
```bash
forge test --match-path test/unit/AMM.t.sol --gas-report | tee artifacts/logs/forge/task3-amm-gas.log
```

4. **Operation gas numbers for metric table**
```bash
grep -E "AMM|addLiquidity|removeLiquidity|swap|getAmountOut" artifacts/logs/forge/task3-amm-gas.log
```
