-- One row per seller: id + location, columns renamed to drop the seller_ prefix.
select
    seller_id,
    seller_zip_code_prefix          as zip_prefix,
    seller_city                     as city,
    seller_state                    as state
from {{ source('raw', 'sellers') }}
