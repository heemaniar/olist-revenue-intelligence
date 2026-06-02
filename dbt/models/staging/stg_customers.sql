-- customer_id is per-ORDER; customer_unique_id is the real person.
select
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix        as zip_prefix,
    customer_city                   as city,
    customer_state                  as state
from {{ source('raw', 'customers') }}
