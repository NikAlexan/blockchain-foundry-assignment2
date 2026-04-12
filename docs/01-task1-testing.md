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

## Evidence
### Unit tests passing output
![Task 1 Unit Tests](../artifacts/screenshots/task1-fuzz-invariant/screen%201.png)

### Fuzz tests passing output
![Task 1 Fuzz Tests](../artifacts/screenshots/task1-fuzz-invariant/screen%202.png)

### Invariant tests passing output
![Task 1 Invariant Tests](../artifacts/screenshots/task1-fuzz-invariant/screen%203.png)

### Coverage output/report
![Task 1 Coverage Part 1](../artifacts/screenshots/task1-fuzz-invariant/screen%204-1.png)
![Task 1 Coverage Part 2](../artifacts/screenshots/task1-fuzz-invariant/screen%204-2.png)
![Task 1 Coverage Part 3](../artifacts/screenshots/task1-fuzz-invariant/screen%204-3.png)

### Key test summary/log excerpt
![Task 1 Summary](../artifacts/screenshots/task1-fuzz-invariant/screen%205.png)
