-- Customer↔seller distance (km) per order, via zip-prefix centroids.
-- Olist ships the geolocation table specifically for this; BigQuery's ST_DISTANCE
-- on GEOG points does the haversine math. One representative seller per order
-- (multi-seller orders are rare). Orders missing either centroid drop out.
with order_cust as (
    select o.order_id, c.zip_prefix as cust_zip
    from {{ ref('stg_orders') }} o
    join {{ ref('stg_customers') }} c on c.customer_id = o.customer_id
),
order_sell as (
    select order_id, any_value(seller_id) as seller_id
    from {{ ref('stg_order_items') }}
    group by order_id
),
geo as (
    select cast(zip_prefix as string) as zip_prefix, lat, lng
    from {{ ref('stg_geolocation') }}
)
select
    oc.order_id,
    round(
        st_distance(st_geogpoint(cg.lng, cg.lat), st_geogpoint(sg.lng, sg.lat)) / 1000.0,
        1
    ) as distance_km
from order_cust oc
join order_sell os using (order_id)
left join {{ ref('stg_sellers') }} s on s.seller_id = os.seller_id
left join geo cg on cg.zip_prefix = cast(oc.cust_zip as string)
left join geo sg on sg.zip_prefix = cast(s.zip_prefix as string)
where cg.lat is not null and sg.lat is not null
