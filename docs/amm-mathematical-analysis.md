# AMM Mathematical Analysis (Task 4)

This note analyzes a two-asset constant-product AMM with reserves \(x\) (token A) and \(y\) (token B), invariant \(k\), and swap fee \(f=0.003\) (0.3%).

---

## 1) Derivation of \(x\,y=k\) and why it works

### Setup
Let pool reserves be \((x,y)\). The AMM state is constrained by
\[
xy = k,
\]
where \(k\) is constant during a fee-free swap.

If a trader inputs \(\Delta x\) of token A and receives \(\Delta y\) of token B, post-trade reserves are
\[
x' = x + \Delta x,\qquad y' = y - \Delta y.
\]
Imposing the invariant:
\[
(x+\Delta x)(y-\Delta y)=xy.
\]
Solve for output:
\[
\Delta y = y - \frac{xy}{x+\Delta x} = \frac{y\,\Delta x}{x+\Delta x}.
\]
Symmetrically, for input \(\Delta y\):
\[
\Delta x = \frac{x\,\Delta y}{y+\Delta y}.
\]

### Marginal price from the curve
From \(y=k/x\):
\[
\frac{dy}{dx}=-\frac{k}{x^2}=-\frac{y}{x}.
\]
The spot price (token A in token B units) is
\[
P_{A\to B}=\frac{y}{x}.
\]
Thus price is endogenous to reserves: buying A (adding B, removing A) increases \(P\); selling A decreases \(P\).

### Why this mechanism works
1. **Always-on liquidity**: for any finite trade, output is computable directly from reserves.
2. **Self-balancing inventory**: trades move reserves and therefore move price against the trader (slippage), stabilizing the pool.
3. **No order book required**: pricing is algorithmic and local to pool state.
4. **Path-independent state variable**: \(k\) (without fees) summarizes feasible reserve states.

Compact example (no fee): if \(x=y=1000\), then \(k=10^6\). For \(\Delta x=100\):
\[
\Delta y = \frac{1000\cdot100}{1100}=90.9091.
\]
New reserves: \((1100,909.0909)\), product remains \(10^6\) (up to rounding).

---

## 2) Effect of 0.3% fee on invariant \(k\) over time

With fee \(f\), only effective input \(\Delta x_{\text{eff}}=(1-f)\Delta x\) participates in pricing; full \(\Delta x\) is kept in reserves.

For token A input:
\[
\Delta y = \frac{y\,\Delta x_{\text{eff}}}{x+\Delta x_{\text{eff}}}
=\frac{y(1-f)\Delta x}{x+(1-f)\Delta x}.
\]
Post-trade reserves:
\[
x' = x+\Delta x,
\qquad
y' = y-\Delta y = y\frac{x}{x+(1-f)\Delta x}.
\]
Therefore
\[
k' = x'y' = (x+\Delta x)\,y\frac{x}{x+(1-f)\Delta x}
= k\cdot\frac{x+\Delta x}{x+(1-f)\Delta x}.
\]
Since \(f>0\):
\[
\frac{x+\Delta x}{x+(1-f)\Delta x}>1 \implies k'>k.
\]
So each fee-paying swap increases \(k\) (ignoring integer rounding). Economically, fees accumulate in pool reserves and are claimable by LPs via LP tokens.

For small trades \((\Delta x\ll x)\):
\[
\frac{k'}{k}\approx 1 + f\frac{\Delta x}{x}.
\]
So \(k\)-growth is approximately linear in fee rate and trade size relative to depth.

Numeric example: \(x=y=1000\), \(\Delta x=100\), \(f=0.003\):
\[
\Delta y\approx\frac{1000\cdot 99.7}{1099.7}=90.6611,
\]
\[
x'=1100,\ y'\approx909.3389,
\]
\[
k'\approx1{,}000{,}272.8>1{,}000{,}000.
\]

---

## 3) Impermanent loss (IL) derivation and \(2\times\) price change

Assume initial external price of A in B units is \(P_0=1\), and pool starts at \(x_0=y_0=1\) (normalization). LP deposits equal value: total value \(V_0=2\) (in B units).

Let new market price be \(P_1=rP_0=r\). Arbitrage enforces pool price \(y/x=r\) with invariant \(xy=1\). Solving:
\[
x_1=\frac{1}{\sqrt r},\qquad y_1=\sqrt r.
\]
LP position value after reprice:
\[
V_{\text{LP}}(r)=x_1\cdot r + y_1=\frac{r}{\sqrt r}+\sqrt r=2\sqrt r.
\]
If LP had simply held initial assets (HODL):
\[
V_{\text{HODL}}(r)=1\cdot r + 1 = r+1.
\]
Relative performance:
\[
\frac{V_{\text{LP}}}{V_{\text{HODL}}}=\frac{2\sqrt r}{1+r}.
\]
Impermanent loss (as a fraction vs HODL):
\[
\text{IL}(r)=\frac{2\sqrt r}{1+r}-1.
\]
Equivalent percentage loss magnitude:
\[
\text{IL\%}_{\text{mag}}(r)=\left(1-\frac{2\sqrt r}{1+r}\right)\times100\%.
\]

For a \(2\times\) price increase (\(r=2\)):
\[
\frac{V_{\text{LP}}}{V_{\text{HODL}}}=\frac{2\sqrt2}{3}\approx0.9428,
\]
\[
\text{IL}(2)\approx-0.0572\quad\Rightarrow\quad \text{loss magnitude}\approx5.72\%.
\]
By symmetry, \(r=0.5\) yields the same IL magnitude.

Interpretation: IL grows with divergence from entry price; fees can offset or exceed IL depending on realized volume.

---

## 4) Price impact as function of trade size vs reserves

Let \(\alpha=\Delta x/x\) be trade size relative to input reserve depth.

### No fee
Output:
\[
\Delta y = y\frac{\alpha}{1+\alpha}.
\]
Average execution price (B per A):
\[
P_{\text{avg}}=\frac{\Delta y}{\Delta x}=\frac{y}{x}\cdot\frac{1}{1+\alpha}=P_0\frac{1}{1+\alpha}.
\]
Spot after trade:
\[
P_1=\frac{y'}{x'}=\frac{y/x}{(1+\alpha)^2}=P_0\frac{1}{(1+\alpha)^2}.
\]
So impact scales nonlinearly with \(\alpha\): doubling trade size relative to reserves more than doubles slippage.

A common average-price impact metric vs pre-trade spot:
\[
\text{Impact}_{\text{avg}} = 1-\frac{P_{\text{avg}}}{P_0}=\frac{\alpha}{1+\alpha}.
\]
Small-trade approximation: \(\text{Impact}_{\text{avg}}\approx\alpha\).

### With fee \(f\)
Replace \(\alpha\) in pricing by effective \(\alpha_{\text{eff}}=(1-f)\Delta x/x\). Then
\[
P_{\text{avg,fee}}=P_0\frac{1-f}{1+\alpha_{\text{eff}}}.
\]
Observed trader execution worsens from two components:
1. **Curve slippage** (depends on depth \(x\), \(y\), size \(\Delta x\));
2. **Fee wedge** (multiplicative \(1-f\) factor on effective input).

Compact example (no fee): \(x=y=1000\), \(\Delta x=100\Rightarrow\alpha=0.1\).
\[
P_{\text{avg}} = P_0/1.1 \approx 0.9091P_0,
\]
~9.09% average impact; post-trade spot is \(P_0/1.21\approx0.8264P_0\).

---

## 5) Comparison to Uniswap V2 and missing features in this assignment AMM

The assignment AMM scaffold (`src/AMM.sol`) defines reserves, LP token, and interface for add/remove/swap/getAmountOut, but core logic is not implemented yet (`NotImplemented`). Relative to production Uniswap V2-style pairs, the following are notable.

### Shared core idea
- Constant-product pricing with reserve-based spot price.
- LP shares represent pro-rata claim on reserves.
- Fee-on-swap model (targeting 0.3% in this task).

### Missing or simplified vs Uniswap V2
1. **No implemented swap/liquidity math yet**
   - Uniswap V2 has fully audited mint/burn/swap invariants, including exact reserve update ordering and checks.

2. **No router/periphery layer**
   - Uniswap V2 Router handles path-based multi-hop swaps, exact-in/exact-out variants, ETH wrapping, deadline/permit conveniences.
   - Assignment AMM exposes only direct pair-level methods.

3. **LP token is minimal, non-standard**
   - `LPToken.sol` supports mint/burn and balance tracking only; no ERC-20 allowance/approve/transferFrom semantics.
   - Uniswap V2 LP token is ERC-20 compatible (transferable with allowances).

4. **No TWAP oracle accumulators**
   - Uniswap V2 tracks cumulative prices (`price0CumulativeLast`, `price1CumulativeLast`) for time-weighted oracle construction.
   - Assignment AMM has no on-chain oracle state.

5. **No protocol fee switch (`feeTo`)**
   - Uniswap V2 can route a portion of LP fees to protocol via `kLast`-based minting when enabled.
   - Assignment target focuses on LP fee only.

6. **No flash swaps / callback hooks**
   - Uniswap V2 supports optimistic output with callback repayment in same transaction.
   - Assignment AMM does not define this behavior.

7. **Reduced safety/edge-case handling**
   - Production pairs include stronger handling for reentrancy lock, token transfer quirks, `MINIMUM_LIQUIDITY`, and precise reserve sync semantics.
   - Assignment scaffold is educational and intentionally compact.

### Practical implication
This assignment AMM is appropriate for studying invariant math, fee dynamics, LP accounting, and slippage mechanics. It is not feature-complete relative to Uniswap V2 production architecture (factory + pair + router + oracle-facing primitives + hardened edge-case handling).

---

## Summary formulas
\[
\Delta y = \frac{y\,\Delta x}{x+\Delta x}\quad(\text{no fee}),
\qquad
\Delta y = \frac{y(1-f)\Delta x}{x+(1-f)\Delta x}\quad(\text{with fee})
\]
\[
\frac{k'}{k}=\frac{x+\Delta x}{x+(1-f)\Delta x}>1
\]
\[
\text{IL}(r)=\frac{2\sqrt r}{1+r}-1,
\qquad
\text{IL}(2)\approx-5.72\%
\]
\[
\text{Impact}_{\text{avg}}=\frac{\alpha}{1+\alpha},\quad \alpha=\Delta x/x.
\]
