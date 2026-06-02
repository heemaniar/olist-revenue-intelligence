"""
load_bigquery.py — Land the 9 raw Olist CSVs in BigQuery as dbt sources.

EL step (in production this would be Fivetran/Airbyte). Reads the Kaggle CSVs
from data/ and loads them as typed raw tables. dbt does the rest.

Setup:
    1. Download the dataset from
       https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
       and unzip the 9 CSVs into ./data/
    2. gcloud auth application-default login
    3. BQ_PROJECT=mallpulse-hackathon BQ_DATASET=olist_core python load_bigquery.py

After this:  cd dbt && dbt build --project-dir . --profiles-dir .
"""

import os
from pathlib import Path

import pandas as pd
from google.cloud import bigquery

PROJECT  = os.getenv("BQ_PROJECT") or os.getenv("GOOGLE_CLOUD_PROJECT")
DATASET  = os.getenv("BQ_DATASET", "olist_core")
LOCATION = os.getenv("BQ_LOCATION", "US")
DATA     = Path(__file__).resolve().parent / "data"

SF = bigquery.SchemaField
# filename (in data/)  ->  (bq table name, schema)
TABLES = {
    "olist_orders_dataset.csv": ("orders", [
        SF("order_id", "STRING"), SF("customer_id", "STRING"),
        SF("order_status", "STRING"),
        SF("order_purchase_timestamp", "TIMESTAMP"),
        SF("order_approved_at", "TIMESTAMP"),
        SF("order_delivered_carrier_date", "TIMESTAMP"),
        SF("order_delivered_customer_date", "TIMESTAMP"),
        SF("order_estimated_delivery_date", "TIMESTAMP"),
    ]),
    "olist_order_items_dataset.csv": ("order_items", [
        SF("order_id", "STRING"), SF("order_item_id", "INTEGER"),
        SF("product_id", "STRING"), SF("seller_id", "STRING"),
        SF("shipping_limit_date", "TIMESTAMP"),
        SF("price", "FLOAT64"), SF("freight_value", "FLOAT64"),
    ]),
    "olist_order_payments_dataset.csv": ("order_payments", [
        SF("order_id", "STRING"), SF("payment_sequential", "INTEGER"),
        SF("payment_type", "STRING"), SF("payment_installments", "INTEGER"),
        SF("payment_value", "FLOAT64"),
    ]),
    "olist_order_reviews_dataset.csv": ("order_reviews", [
        SF("review_id", "STRING"), SF("order_id", "STRING"),
        SF("review_score", "INTEGER"),
        SF("review_comment_title", "STRING"),
        SF("review_comment_message", "STRING"),
        SF("review_creation_date", "TIMESTAMP"),
        SF("review_answer_timestamp", "TIMESTAMP"),
    ]),
    "olist_customers_dataset.csv": ("customers", [
        SF("customer_id", "STRING"), SF("customer_unique_id", "STRING"),
        SF("customer_zip_code_prefix", "STRING"),
        SF("customer_city", "STRING"), SF("customer_state", "STRING"),
    ]),
    "olist_sellers_dataset.csv": ("sellers", [
        SF("seller_id", "STRING"), SF("seller_zip_code_prefix", "STRING"),
        SF("seller_city", "STRING"), SF("seller_state", "STRING"),
    ]),
    "olist_products_dataset.csv": ("products", [
        SF("product_id", "STRING"), SF("product_category_name", "STRING"),
        # NB: the source misspells "length" as "lenght" — keep to match the CSV.
        SF("product_name_lenght", "INTEGER"),
        SF("product_description_lenght", "INTEGER"),
        SF("product_photos_qty", "INTEGER"),
        SF("product_weight_g", "INTEGER"),
        SF("product_length_cm", "INTEGER"),
        SF("product_height_cm", "INTEGER"),
        SF("product_width_cm", "INTEGER"),
    ]),
    "olist_geolocation_dataset.csv": ("geolocation", [
        SF("geolocation_zip_code_prefix", "STRING"),
        SF("geolocation_lat", "FLOAT64"), SF("geolocation_lng", "FLOAT64"),
        SF("geolocation_city", "STRING"), SF("geolocation_state", "STRING"),
    ]),
    "product_category_name_translation.csv": ("category_translation", [
        SF("product_category_name", "STRING"),
        SF("product_category_name_english", "STRING"),
    ]),
}

# Columns to force to string on read (ids / zip prefixes — preserve leading zeros).
_STR_COLS = {"order_id", "customer_id", "customer_unique_id", "product_id",
             "seller_id", "review_id",
             "customer_zip_code_prefix", "seller_zip_code_prefix",
             "geolocation_zip_code_prefix"}


def main():
    if not PROJECT:
        raise SystemExit("Set BQ_PROJECT or GOOGLE_CLOUD_PROJECT.")
    if not DATA.exists() or not any(DATA.glob("*.csv")):
        raise SystemExit(f"No CSVs in {DATA}. Download the Olist dataset first.")
    client = bigquery.Client(project=PROJECT, location=LOCATION)
    ds = bigquery.Dataset(f"{PROJECT}.{DATASET}")
    ds.location = LOCATION
    client.create_dataset(ds, exists_ok=True)
    print(f"→ dataset {PROJECT}.{DATASET} ({LOCATION})")

    for fname, (table, schema) in TABLES.items():
        path = DATA / fname
        if not path.exists():
            print(f"  ⚠️  skip {table}: {fname} not found")
            continue
        str_cols = {f.name: str for f in schema
                    if f.name in _STR_COLS}
        ts_cols = [f.name for f in schema if f.field_type == "TIMESTAMP"]
        df = pd.read_csv(path, dtype=str_cols, encoding="utf-8-sig")  # strip BOM
        for col in ts_cols:
            if col in df.columns:
                df[col] = pd.to_datetime(df[col], errors="coerce")
        job = client.load_table_from_dataframe(
            df, f"{PROJECT}.{DATASET}.{table}",
            job_config=bigquery.LoadJobConfig(
                schema=schema, write_disposition="WRITE_TRUNCATE"),
        )
        job.result()
        print(f"  ✅ {table:<20} {len(df):>8,} rows")

    print(f"\nRaw Olist tables loaded into {PROJECT}.{DATASET}. "
          f"Next:  cd dbt && dbt build --project-dir . --profiles-dir .")


if __name__ == "__main__":
    main()
