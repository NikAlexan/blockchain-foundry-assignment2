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

## Evidence
### USDC `totalSupply` fork test output
![Task 2 USDC Fork Test](../artifacts/screenshots/task2-fork-testing/screen%201.png)

### Uniswap V2 swap fork test output
![Task 2 Swap Fork Test](../artifacts/screenshots/task2-fork-testing/screen%202%7C4.png)

### Fork suite passing summary
![Task 2 Fork Suite Summary](../artifacts/screenshots/task2-fork-testing/screen%202%7C4.png)

### `createSelectFork` / `rollFork` log excerpt
![Task 2 Fork Log Excerpt](../artifacts/screenshots/task2-fork-testing/screen%202%7C4.png)
