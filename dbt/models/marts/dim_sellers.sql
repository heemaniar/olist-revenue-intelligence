-- Seller dimension: id + location (state, city) for joins and geo breakdowns.
select
    seller_id,
    state,
    city
from {{ ref('stg_sellers') }}
