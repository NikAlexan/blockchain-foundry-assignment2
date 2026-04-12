# Task 2 Report — Fork Testing Against Mainnet

## Objective
Use Foundry fork testing to interact with real deployed mainnet contracts.

## What was implemented
- Mainnet fork tests in `test/fork/ForkMainnet.t.sol`.
- USDC `totalSupply()` read from real USDC contract on fork.
- Uniswap V2 router swap simulation on fork.
- Block progression demonstration with `vm.rollFork`.

## `vm.createSelectFork` and `vm.rollFork`
`vm.createSelectFork(rpcUrl, blockNumber)` creates and selects a fork from a remote RPC endpoint, optionally pinning a specific block for deterministic behavior.

`vm.rollFork(newBlockNumber)` advances the currently selected fork to a different block number without recreating the fork, enabling controlled block/time progression testing.

## Benefits and limitations of fork testing
### Benefits
- High realism: tests run against production contracts and real state.
- Better integration confidence than isolated mocks.
- Faster iteration than deploying full integration environments from scratch.

### Limitations
- Requires stable RPC infrastructure and rate limits can affect runs.
- Results can drift if tests are not pinned to a fixed block.
- Fork tests complement (not replace) unit/fuzz/invariant suites.

## Evidence placeholders
- `[INSERT SCREENSHOT: USDC totalSupply fork test output]`
- `[INSERT SCREENSHOT: Uniswap V2 swap fork test output]`
- `[INSERT SCREENSHOT: fork test suite passing summary]`
- `[INSERT LOG EXCERPT: createSelectFork/rollFork related run output]`

## Commands to capture each screenshot
Run from project root:

```bash
cd Project
export PATH="$HOME/.foundry/bin:$PATH"
mkdir -p artifacts/logs/forge
set -a && source .env && set +a
```

1. **USDC `totalSupply` fork test output**
```bash
forge test --match-path test/fork/ForkMainnet.t.sol --match-test testFork_ReadUSDC_TotalSupply -vv | tee artifacts/logs/forge/task2-usdc.log
```

2. **Uniswap V2 swap fork test output**
```bash
forge test --match-path test/fork/ForkMainnet.t.sol --match-test testFork_UniswapV2SwapExactETHForUSDC -vv | tee artifacts/logs/forge/task2-swap.log
```

3. **Full fork suite passing summary**
```bash
forge test --match-path test/fork/ForkMainnet.t.sol -vv | tee artifacts/logs/forge/task2-suite.log
```

4. **`createSelectFork` / `rollFork` excerpt**
```bash
forge test --match-path test/fork/ForkMainnet.t.sol --match-test testFork_RollFork_AdvancesSnapshotBlock -vv | tee artifacts/logs/forge/task2-rollfork.log
grep -E "createSelectFork|rollFork|FORK_BLOCK|PASS|Ran" artifacts/logs/forge/task2-rollfork.log
```
