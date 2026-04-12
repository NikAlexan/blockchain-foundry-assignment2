# Task 6 Report — CI/CD Pipeline for Smart Contracts

## Objective
Create and document a CI pipeline that validates build quality, test correctness, gas reporting, and static analysis.

## Workflow file
- `.github/workflows/test.yml`

## Pipeline stages
1. Checkout source code.
2. Install Foundry toolchain.
3. Bootstrap dependencies (forge-std) when needed.
4. Compile contracts (`forge build`).
5. Run test suites (`forge test`).
6. Generate gas report (`forge test --gas-report`).
7. Run Slither static analysis.

## Why each stage matters
- Build/test stages prevent regressions.
- Gas reporting tracks performance and cost drift.
- Slither catches high-impact static vulnerabilities early.

## Required environment
- GitHub secret: `MAINNET_RPC_URL` for fork tests.

## Evidence
### Successful GitHub Actions run summary
![Task 6 GitHub Actions Summary](../artifacts/screenshots/task6-ci-cd/screen%201.png)

### Test stage logs
![Task 6 Test Stage](../artifacts/screenshots/task6-ci-cd/screen%202.png)

### Gas report stage output
![Task 6 Gas Report](../artifacts/screenshots/task6-ci-cd/screen%202.png)

### Slither stage output
![Task 6 Slither Stage](../artifacts/screenshots/task6-ci-cd/screen%203.png)

### Key workflow run lines
![Task 6 Workflow Excerpt](../artifacts/screenshots/task6-ci-cd/screen%203.png)
