# Prompt Engineering — Voice-of-Customer review tagging

How the Claude layer (`analyze_reviews.py`) is designed. The point isn't "we
called an LLM" — it's the deliberate choices that make it cheap, reliable, and
analyzable.

## Task
Turn ~2,000 free-text **Portuguese** Olist reviews into structured rows the
warehouse and dashboard can use: `sentiment`, `themes[]`, `summary_en`.

## The five choices that matter

1. **Structured output, enum-constrained.** The response is forced to a JSON
   schema with `sentiment` ∈ {positive, neutral, negative} and `themes` drawn
   from a fixed 9-value enum. No free-text label drift, no parsing regex — every
   row lands in a known column with a known vocabulary, so it aggregates cleanly.

2. **Prompt caching on the taxonomy.** The system prompt (the theme definitions +
   instructions, ~250 tokens) is identical on every call and marked
   `cache_control: ephemeral`. After the first call it's served from cache at
   ~0.1× cost — the per-review marginal cost is essentially just the review text.

3. **Multilingual by design.** Input is Portuguese; the model returns **English**
   theme tags and an English one-line summary. One model spans the language gap —
   no separate translation step.

4. **Right-sized model + concurrency.** This is bounded classification, not
   reasoning — so **Haiku**, not Opus (cost, speed). An 8-way thread pool turns a
   ~30-minute serial run into a few minutes; the SDK auto-retries rate limits.

5. **Explode in the warehouse, not the prompt.** The model returns a *list* of
   themes per review; Python writes one row per (review, theme) to
   `review_themes`. A multi-label answer becomes a tidy table a Data Studio pivot
   (theme × category) reads directly — modeling stays in SQL, the LLM only tags.

## Schema (the contract)
```json
{ "sentiment": "positive|neutral|negative",
  "themes": ["delivery", "product_quality", "not_as_described",
             "wrong_or_missing_item", "damaged", "customer_service",
             "price_value", "praise", "other"],
  "summary_en": "<= 15 words" }
```

## Cost
~2,000 reviews on Haiku with the cached system prompt ≈ **$1**. Full ~40k via the
Batches API (50% off) ≈ $10 — not needed for the demo. Sample is `--sample`.

## Reliability
Per-review try/except: a failed/garbled response is counted and skipped, never
crashing the batch. Output is `WRITE_TRUNCATE`, so re-runs are idempotent.
