# Assignment 2 — DeFi Protocol Development

This repository contains a Foundry-based implementation for Assignment 2 tasks (testing, fork tests, AMM, lending simulation, and CI/CD pipeline).

## Quick start
1. Install Foundry (`forge`, `cast`, `anvil`).
2. Add Foundry binaries to PATH if needed:
   - `export PATH="$HOME/.foundry/bin:$PATH"`
3. Copy env template and set RPC:
   - `cp .env.example .env`
   - set `MAINNET_RPC_URL=<your-mainnet-rpc>`
4. Install test library:
   - `forge install foundry-rs/forge-std --no-git`

## Local commands
- Build: `forge build`
- Run all tests: `forge test`
- Run non-fork tests: `forge test --no-match-path "test/fork/*"`
- Run fork tests: `forge test --match-path "test/fork/*" -vvv`
- Coverage (non-fork): `forge coverage --no-match-path "test/fork/*"`
- Gas report: `forge test --gas-report`

## Fork testing notes (Task 2)
- Required env variable: `MAINNET_RPC_URL`.
- Fork tests pin block state via `vm.createSelectFork(rpc, blockNumber)` for determinism.
- `vm.rollFork(newBlock)` is used to advance the selected fork to another block height.

## CI/CD pipeline (Task 6)
Workflow file: `.github/workflows/test.yml`
1. Checkout repository.
2. Install Foundry toolchain.
3. Bootstrap dependencies (`forge-std`) when missing.
4. Compile contracts.
5. Run full test suite.
6. Generate gas report.
7. Run Slither static analysis.

### CI environment requirement
- Required GitHub secret: `MAINNET_RPC_URL`.

## Project structure
- `src/` — contracts (`AMM.sol`, `LPToken.sol`, `LendingPool.sol`, `mocks/SimpleERC20.sol`)
- `test/` — `unit`, `fuzz`, `invariant`, `fork`
- `script/` — deployment scripts
- `.github/workflows/test.yml` — CI pipeline
- `docs/` — assignment reports and analysis
- `artifacts/` — placeholders for screenshots/logs/user-provided evidence

## Documentation and submission
- Submission checklist: `SUBMISSION_CHECKLIST.md`
- AMM math analysis: `docs/amm-mathematical-analysis.md`
- Task-by-task documentation package: `docs/01-task1-testing.md` to `docs/06-final-submission-map.md`
