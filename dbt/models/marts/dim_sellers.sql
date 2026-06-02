select
    seller_id,
    state,
    city
from {{ ref('stg_sellers') }}
