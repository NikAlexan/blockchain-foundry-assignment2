# Task 1 Report — Advanced Testing with Foundry

## Objective
Implement a basic ERC-20 token and validate it with unit, fuzz, and invariant testing in Foundry.

## What was implemented
- `src/mocks/SimpleERC20.sol` with `mint`, `transfer`, `approve`, and `transferFrom`.
- Unit test suite in `test/unit/SimpleERC20.t.sol` (mint, transfer, approvals, edge cases, reverts).
- Fuzz test suite in `test/fuzz/SimpleERC20Fuzz.t.sol` (randomized transfer behaviors).
- Invariant suite in `test/invariant/SimpleERC20Invariant.t.sol`.

## Validation summary
- Unit tests executed and passing.
- Fuzz tests executed with randomized inputs and passing.
- Invariant tests executed with multiple runs/calls and passing.
- Coverage generated for non-fork scope.

## Unit testing vs fuzz testing (brief explanation)
Unit tests validate deterministic, explicitly designed behaviors and edge cases. They are best when you need precise guarantees for known scenarios (e.g., allowance updates, zero-address checks, exact revert reasons).

Fuzz tests validate behavior over broad randomized input ranges. They are best for discovering hidden issues in arithmetic, state transitions, and unexpected input combinations that are expensive to enumerate manually.

In practice, use both: unit tests for specification fidelity, fuzz tests for robustness under high input variance, and invariants for global safety properties.

## Evidence placeholders
- `[INSERT SCREENSHOT: Task 1 unit tests passing output]`
- `[INSERT SCREENSHOT: Task 1 fuzz tests passing output]`
- `[INSERT SCREENSHOT: Task 1 invariant tests passing output]`
- `[INSERT SCREENSHOT: forge coverage output/report]`
- `[INSERT LOG EXCERPT: key test summary lines for Task 1]`

## Commands to capture each screenshot
Run from project root:

```bash
cd Project
export PATH="$HOME/.foundry/bin:$PATH"
mkdir -p artifacts/logs/forge
```

1. **Unit tests passing output**
```bash
forge test --match-path test/unit/SimpleERC20.t.sol -vv | tee artifacts/logs/forge/task1-unit.log
```

2. **Fuzz tests passing output**
```bash
forge test --match-path test/fuzz/SimpleERC20Fuzz.t.sol -vv | tee artifacts/logs/forge/task1-fuzz.log
```

3. **Invariant tests passing output**
```bash
forge test --match-path test/invariant/SimpleERC20Invariant.t.sol -vv | tee artifacts/logs/forge/task1-invariant.log
```

4. **Coverage output/report**
```bash
forge coverage --no-match-path "test/fork/*" | tee artifacts/logs/forge/task1-coverage.log
```

5. **Key log excerpt lines**
```bash
grep -E "Ran|passed|failed|invariant_" artifacts/logs/forge/task1-*.log
```
