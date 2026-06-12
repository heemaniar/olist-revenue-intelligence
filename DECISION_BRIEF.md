# Decision Brief — Olist Marketplace Revenue & CX

**For:** Leadership (Revenue, Logistics, Growth) · **From:** Analytics · **Basis:** 98k valid orders, 2016–2018 (real Olist data)

**Bottom line:** The marketplace is **acquisition-rich but retention-poor**, and the
single biggest, most fixable lever on satisfaction — and therefore on the repeat
revenue we don't yet capture — is **delivery speed**. Three moves below.

---

### 1. Late delivery is the #1 satisfaction killer — and it's a *carrier* problem, not seller dispatch
**Evidence.** Review score falls monotonically with delivery time: **4.46★ at 0–3 days → 3.05★ at 22+ days** (40% detractors vs 7% for fast deliveries). Decomposing the order journey pinpoints the cause: when an order is late, **carrier transit balloons to 25.7 days (vs 7.8 on-time), while seller handling barely moves (5.8 vs 3.0)** — lateness is a transit problem, not a dispatch one. And it's **distance-driven**: 0–50 km orders deliver in **6.1 days at 4.28★**; 1,000+ km orders take **19.1 days at 4.02★** with ~2× the late rate.
**Recommendation.** This is a **carrier/network fix, not seller onboarding**: hold carriers to transit SLAs, add **regional carriers or fulfillment nodes for long-distance lanes**, and set promised dates *by distance band* so expectations match reality.
**Projected impact.** ~11k orders/period exit detractor territory → a measurable review lift and, given the retention finding below, the clearest path to repeat revenue.

### 2. Retention is the real gap — 3% repeat is the opportunity, not a footnote
**Evidence.** Only **3.1%** of customers (of 96k) order more than once. Acquisition is strong; the marketplace simply doesn't bring customers back.
**Recommendation.** Treat **post-delivery experience as the retention engine** (Finding 1 is the lever) and stand up a basic win-back program for first-time buyers with a positive (4–5★) experience.
**Projected impact.** Repeat rate is a high-leverage multiplier on GMV — even a 1pt lift on a 96k base is ~1k incremental repeat customers; the delivery fix is the cheapest way to earn it.

### 3. Revenue is seller-concentrated — protect the top, grow the tail
**Evidence.** The **top 10% of sellers drive 67.5% of GMV**.
**Recommendation.** Formalize a seller-success tier for the top decile (SLA, support, inventory), and a light onboarding/quality program for the long tail.
**Projected impact.** Reduces single-seller revenue risk and creates a second growth vector beyond customer acquisition.

---

*All figures reconcile to the governed marts (`METRICS.md`); GMV integrity is dbt-tested. Next: AI review-theme analysis (Voice of Customer) to name the specific complaint drivers behind the low scores in Finding 1.*
