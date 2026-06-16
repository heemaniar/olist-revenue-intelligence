# Decision Brief — Olist Marketplace Revenue & CX

**Audience:** Leadership (Revenue, Logistics, Growth) · **Prepared by:** Analytics ·
**Basis:** ~98k valid orders (2017–2018), real Olist marketplace data.
*Real public dataset (© Olist, CC BY-NC-SA 4.0) — non-commercial demonstration.*

**Bottom line:** The marketplace is **acquisition-rich but retention-poor**. The two most
fixable satisfaction levers — and therefore the repeat revenue we don't yet capture — are
**delivery speed** (the volume problem) and **fulfillment accuracy** (the severity
problem). Four decisions below.

## Decisions at a glance

| # | Decision | Why now | Expected impact | Owner |
|---|----------|---------|-----------------|-------|
| 1 | **Fix carrier transit on long-distance lanes** | Lateness is carrier transit (25.7 vs 7.8 days), distance-driven — not seller dispatch. | Lifts review scores on the worst lanes → repeat revenue. | Logistics |
| 2 | **Stand up a retention / win-back program** | Only **3.1%** of customers reorder. | A high-leverage GMV multiplier on a 96k base. | Growth |
| 3 | **Tier seller-success; grow the long tail** | Top 10% of sellers drive **67.5%** of GMV. | De-risks single-seller revenue + a 2nd growth vector. | Marketplace |
| 4 | **Fix fulfillment accuracy + seller response** | Wrong/missing-item (1.66★) and customer-service (2.28★) are the lowest-rated themes. | Lifts the most score-destroying experiences. | Seller Ops |

## The evidence

### 1. Late delivery is the #1 satisfaction killer — and it's a *carrier* problem, not seller dispatch
**Evidence.** Review score falls monotonically with delivery time: **4.46★ at 0–3 days →
3.05★ at 22+ days** (40% detractors vs 7% for fast deliveries). Decomposing the journey:
when an order is late, **carrier transit balloons to 25.7 days (vs 7.8 on-time), while
seller handling barely moves (5.8 vs 3.0)**. And it's distance-driven: 0–50 km orders
deliver in **6.1 days at 4.28★**; 1,000+ km in **19.1 days at 4.02★**.
**Recommendation.** A carrier/network fix, not seller onboarding: hold carriers to transit
SLAs, add regional carriers/fulfillment nodes for long lanes, and set promised dates *by
distance band*.
**Impact.** ~11k orders/period exit detractor territory → measurable review lift and the
clearest path to repeat revenue.

### 2. Retention is the real gap — 3% repeat is the opportunity
**Evidence.** Only **3.1%** of 96k customers order more than once. Acquisition is strong;
the marketplace simply doesn't bring customers back.
**Recommendation.** Treat post-delivery experience as the retention engine (Findings 1 & 4
are the levers) and run a win-back program for first-time buyers with a positive (4–5★)
experience.
**Impact.** Even a 1-pt lift on 96k is ~1k incremental repeat customers; the delivery and
accuracy fixes are the cheapest way to earn it.

### 3. Revenue is seller-concentrated — protect the top, grow the tail
**Evidence.** The **top 10% of sellers drive 67.5% of GMV**.
**Recommendation.** Formalize a seller-success tier for the top decile (SLA, support,
inventory) and a light onboarding/quality program for the long tail.
**Impact.** Reduces single-seller revenue risk; creates a second growth vector beyond
customer acquisition.

### 4. Beyond speed, fulfillment *accuracy* is the hidden satisfaction driver (AI review tagging)
**Evidence.** Claude tagged a 1,500-review sample by theme + sentiment (0 failures; 38%
negative). Delivery is the most *frequent* complaint (301 negative mentions), but the most
*score-destroying* themes are **wrong/missing item (1.66★)**, **customer service (2.28★)**,
and **not-as-described (2.39★)** — versus delivery's **3.64★**. Star ratings alone couldn't
separate these; the LLM tagging did.
**Recommendation.** A second lever, distinct from Finding 1: tighten listing/description
fidelity and order-picking accuracy at the seller level, plus seller response SLAs. Owner is
marketplace/seller ops — not the carrier.
**Impact.** Targets the lowest-rated experiences; with Finding 1, covers both axes of
dissatisfaction — *speed* and *accuracy*.

## Targets vs. current

| KPI | Current | Target | Note |
|-----|---------|--------|------|
| On-time delivery % | 91.9% | 95% | carrier transit (Decision 1) |
| Avg review score | 4.09★ | 4.3★ | speed + accuracy |
| Repeat-purchase % | 3.1% | 5% | retention (Decision 2) |

---
*All figures reconcile to the governed marts ([`METRICS.md`](METRICS.md)) — one source of
truth; GMV integrity is dbt-tested. Review themes (Finding 4) are Claude-tagged on a
1,500-review sample (0 failures).*
