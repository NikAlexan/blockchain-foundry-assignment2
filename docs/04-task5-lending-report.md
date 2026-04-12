# Task 5 Report — Lending Protocol Simulation

## Objective
Implement a simplified lending protocol with collateral deposit, borrowing, repayment, withdrawal constraints, interest accrual, and liquidation.

## What was implemented
- `src/LendingPool.sol`
  - `deposit`
  - `borrow`
  - `repay`
  - `withdraw`
  - `liquidate`
  - `healthFactor`
  - `currentBorrowBalance`
- Position tracking for deposited collateral, borrowed debt, and accrual timestamp.
- LTV constraint (max 75%).
- Linear time-based interest accrual model.
- Liquidation path for undercollateralized accounts.

## Test coverage summary
- Unit tests in `test/unit/LendingPool.t.sol` include:
  - deposit/withdraw flow
  - borrow within and beyond LTV
  - partial/full repay
  - liquidation after simulated price drop
  - interest accrual with `vm.warp`
  - edge cases and revert paths

## Workflow diagram
Provide a workflow diagram for:
`deposit -> borrow -> repay -> withdraw`.

## Evidence
### LendingPool tests passing output
![Task 5 Lending Tests](../artifacts/screenshots/task5-lending-tests/screen%201.png)

### LendingPool gas report section
![Task 5 Lending Gas](../artifacts/screenshots/task5-lending-tests/screen%202.png)

### Workflow diagram image
![Task 5 Workflow Diagram](../artifacts/screenshots/task5-lending-tests/screen%203.svg)

### Liquidation and interest-accrual excerpt
![Task 5 Liquidation and Interest](../artifacts/screenshots/task5-lending-tests/screen%204.png)
