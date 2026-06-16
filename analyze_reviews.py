"""
analyze_reviews.py — Voice-of-Customer: Claude over Portuguese Olist reviews.

Pulls a sample of comment-bearing reviews from BigQuery, classifies each with
Claude (structured output: sentiment + themes + English summary), and writes an
exploded `review_themes` table back to BigQuery for the dashboard's VoC page.

Prompt-engineering choices (see PROMPTS.md):
  • structured output (JSON schema, enum-constrained) → clean, parseable labels
  • cached system prompt (the fixed theme taxonomy) → cheap repeated calls
  • multilingual: Portuguese in, English theme tags + summary out
  • thread-pool concurrency to keep the run a few minutes, not half an hour

Run (Python 3.x venv with anthropic + google-cloud-bigquery):
    export BQ_PROJECT=mallpulse-hackathon BQ_DATASET=olist_core ANTHROPIC_API_KEY=...
    python analyze_reviews.py --sample 2000 --workers 8
"""

import argparse
import collections
import json
import os
import threading
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

import pandas as pd
from google.cloud import bigquery


class RateLimiter:
    """Thread-safe sliding-window limiter to stay under the org's RPM cap."""

    def __init__(self, rpm):
        self.rpm = rpm
        self.calls = collections.deque()
        self.lock = threading.Lock()

    def acquire(self):
        with self.lock:
            now = time.monotonic()
            while self.calls and now - self.calls[0] > 60:
                self.calls.popleft()
            if len(self.calls) >= self.rpm:
                time.sleep(max(60 - (now - self.calls[0]), 0))
                now = time.monotonic()
                while self.calls and now - self.calls[0] > 60:
                    self.calls.popleft()
            self.calls.append(time.monotonic())

PROJECT = os.getenv("BQ_PROJECT") or os.getenv("GOOGLE_CLOUD_PROJECT")
DATASET = os.getenv("BQ_DATASET", "olist_core")
MODEL   = os.getenv("OPS_LLM_MODEL", "claude-haiku-4-5")

THEMES = ["delivery", "product_quality", "not_as_described", "wrong_or_missing_item",
          "damaged", "customer_service", "price_value", "praise", "other"]
SENTIMENTS = ["positive", "neutral", "negative"]

SYSTEM = (
    "You are a CX analyst tagging Portuguese-language e-commerce reviews for a "
    "Brazilian marketplace. For each review, return its overall sentiment, the "
    "themes it raises, and a short ENGLISH summary.\n\n"
    "Themes (choose all that apply):\n"
    "- delivery: shipping speed, lateness, not delivered, tracking\n"
    "- product_quality: quality, defects, durability\n"
    "- not_as_described: differs from the listing/expectation\n"
    "- wrong_or_missing_item: wrong product, missing items, partial order\n"
    "- damaged: arrived broken/damaged\n"
    "- customer_service: seller/support responsiveness\n"
    "- price_value: price, value for money\n"
    "- praise: general satisfaction / recommendation\n"
    "- other: anything else\n\n"
    "Return at least one theme. Summary is English, <= 15 words."
)

SCHEMA = {
    "type": "object",
    "properties": {
        "sentiment": {"type": "string", "enum": SENTIMENTS},
        "themes": {"type": "array", "items": {"type": "string", "enum": THEMES}},
        "summary_en": {"type": "string"},
    },
    "required": ["sentiment", "themes", "summary_en"],
    "additionalProperties": False,
}

WRITE_SCHEMA = [
    bigquery.SchemaField("review_id", "STRING"),
    bigquery.SchemaField("order_id", "STRING"),
    bigquery.SchemaField("category", "STRING"),
    bigquery.SchemaField("review_score", "INTEGER"),
    bigquery.SchemaField("sentiment", "STRING"),
    bigquery.SchemaField("theme", "STRING"),
    bigquery.SchemaField("summary_en", "STRING"),
]


def fetch_reviews(bq, n):
    sql = f"""
        with cat as (
            select order_id, any_value(category) as category
            from `{PROJECT}.{DATASET}.fct_order_items`
            group by order_id
        )
        select r.review_id, r.order_id, r.review_score,
               r.comment_message, coalesce(c.category, 'unknown') as category
        from `{PROJECT}.{DATASET}.int_order_reviews` r
        left join cat c using (order_id)
        where r.has_comment
    """
    df = bq.query(sql).to_dataframe()
    print(f"  {len(df):,} comment-bearing reviews; sampling {n}")
    return df.sample(min(n, len(df)), random_state=7).reset_index(drop=True)


def classify(client, limiter, text):
    limiter.acquire()
    resp = client.messages.create(
        model=MODEL, max_tokens=200,
        system=[{"type": "text", "text": SYSTEM, "cache_control": {"type": "ephemeral"}}],
        messages=[{"role": "user", "content": f"Review (Portuguese):\n{text}"}],
        output_config={"format": {"type": "json_schema", "schema": SCHEMA}},
    )
    out = json.loads(next(b.text for b in resp.content if b.type == "text"))
    themes = out.get("themes") or ["other"]
    return out.get("sentiment", "neutral"), themes, out.get("summary_en", "")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sample", type=int, default=2000)
    ap.add_argument("--workers", type=int, default=4)
    ap.add_argument("--rpm", type=int, default=45)
    args = ap.parse_args()
    if not PROJECT:
        raise SystemExit("Set BQ_PROJECT or GOOGLE_CLOUD_PROJECT.")
    import anthropic
    client = anthropic.Anthropic(max_retries=8)
    limiter = RateLimiter(args.rpm)
    bq = bigquery.Client(project=PROJECT)

    df = fetch_reviews(bq, args.sample)

    rows, done, fails = [], 0, 0
    def work(rec):
        return rec, classify(client, limiter, str(rec["comment_message"]))

    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        futures = [ex.submit(work, r) for _, r in df.iterrows()]
        for fut in as_completed(futures):
            done += 1
            try:
                rec, (sentiment, themes, summary) = fut.result()
                for theme in dict.fromkeys(themes):       # dedup, keep order
                    rows.append({
                        "review_id": rec["review_id"], "order_id": rec["order_id"],
                        "category": rec["category"],
                        "review_score": int(rec["review_score"]),
                        "sentiment": sentiment, "theme": theme, "summary_en": summary,
                    })
            except Exception as e:
                fails += 1
                if fails <= 3:
                    print(f"   ⚠️  fail: {e}")
            if done % 200 == 0:
                print(f"   …{done}/{len(df)}")

    out = pd.DataFrame(rows)
    table = f"{PROJECT}.{DATASET}.review_themes"
    bq.load_table_from_dataframe(
        out, table,
        job_config=bigquery.LoadJobConfig(schema=WRITE_SCHEMA, write_disposition="WRITE_TRUNCATE"),
    ).result()

    print(f"\n✅ wrote {len(out):,} theme rows ({out.review_id.nunique():,} reviews, "
          f"{fails} failures) → {table}")
    print("\nTop themes:")
    print(out.theme.value_counts().head(10).to_string())
    print("\nSentiment mix (by review):")
    print(out.drop_duplicates('review_id').sentiment.value_counts(normalize=True).round(3).to_string())


if __name__ == "__main__":
    main()
