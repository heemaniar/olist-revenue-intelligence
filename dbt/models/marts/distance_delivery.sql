-- Distance band → delivery time, satisfaction, lateness. The distance→delivery→
-- review chain Olist's geolocation table is built for. band_order = clean axis sort.
with b as (
    select
        case
            when distance_km < 50   then '0-50 km'
            when distance_km < 200  then '50-200 km'
            when distance_km < 500  then '200-500 km'
            when distance_km < 1000 then '500-1000 km'
            else '1000+ km'
        end as distance_band,
        case
            when distance_km < 50   then 1
            when distance_km < 200  then 2
            when distance_km < 500  then 3
            when distance_km < 1000 then 4
            else 5
        end as band_order,
        delivery_days, review_score, is_late
    from {{ ref('fct_orders') }}
    where distance_km is not null and delivered_at is not null
)
select
    distance_band,
    any_value(band_order)              as band_order,
    count(*)                           as orders,
    round(avg(delivery_days), 1)       as avg_delivery_days,
    round(avg(review_score), 2)        as avg_review,
    round(avg(if(is_late, 1, 0)), 3)   as late_rate
from b
group by distance_band
