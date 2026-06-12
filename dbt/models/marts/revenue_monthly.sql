select
    purchase_month,
    count(distinct order_id)                                 as orders,
    round(sum(gmv), 2)                                       as gmv,
    round(safe_divide(sum(gmv), count(distinct order_id)), 2) as aov,
    round(avg(review_score), 2)                             as avg_review,
    -- on-time among DELIVERED orders only (is_late null = not delivered, excluded)
    round(avg(case when is_late is true then 0
                   when is_late is false then 1 end), 3)     as on_time_rate,
    -- ⚠️ Olist's usable window is 2017-01 … 2018-08; the edge months are
    -- ramp-up + a data-cutoff stub (1-2 orders) that fake a cliff. Filter the
    -- trend chart on is_complete_month = true.
    date_trunc(date('2017-01-01'), month) <= purchase_month
        and purchase_month <= date_trunc(date('2018-08-01'), month) as is_complete_month
from {{ ref('fct_orders') }}
where is_valid_revenue
group by purchase_month
