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

## Evidence placeholders
- `[INSERT SCREENSHOT: successful GitHub Actions run summary]`
- `[INSERT SCREENSHOT: test stage logs]`
- `[INSERT SCREENSHOT: gas report stage output]`
- `[INSERT SCREENSHOT: Slither stage output]`
- `[INSERT LOG EXCERPT: key workflow run lines]`

## Commands to capture each screenshot
Run from project root:

```bash
cd Project
export PATH="$HOME/.foundry/bin:$PATH"
mkdir -p artifacts/logs/forge artifacts/logs/slither
```

1. **Successful GitHub Actions run summary**
```bash
git add .
git commit -m "docs: add screenshot command references"
git push
```
Then open: `https://github.com/<OWNER>/<REPO>/actions` and screenshot the green successful run row.

2. **Test stage logs (local equivalent and artifact log)**
```bash
forge test --no-match-path "test/fork/*" -vv | tee artifacts/logs/forge/task6-tests.log
```

3. **Gas report stage output (local equivalent and artifact log)**
```bash
forge test --gas-report --no-match-path "test/fork/*" | tee artifacts/logs/forge/task6-gas.log
```

4. **Slither stage output (local equivalent and artifact log)**
```bash
slither src --exclude-dependencies | tee artifacts/logs/slither/task6-slither.log
```

5. **Key workflow run lines**
```bash
grep -E "PASS|Ran|failed|Gas|Slither" artifacts/logs/forge/task6-tests.log artifacts/logs/forge/task6-gas.log artifacts/logs/slither/task6-slither.log
```
