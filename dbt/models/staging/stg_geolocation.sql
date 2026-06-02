-- Raw geolocation has many rows per zip prefix; dedup to one (avg lat/lng).
select
    geolocation_zip_code_prefix             as zip_prefix,
    avg(geolocation_lat)                     as lat,
    avg(geolocation_lng)                     as lng,
    any_value(geolocation_state)            as state
from {{ source('raw', 'geolocation') }}
group by geolocation_zip_code_prefix
