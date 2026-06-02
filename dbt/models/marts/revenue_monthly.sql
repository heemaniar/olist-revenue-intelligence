select
    purchase_month,
    count(distinct order_id)                                 as orders,
    round(sum(gmv), 2)                                       as gmv,
    round(safe_divide(sum(gmv), count(distinct order_id)), 2) as aov,
    round(avg(review_score), 2)                             as avg_review,
    -- on-time among DELIVERED orders only (is_late null = not delivered, excluded)
    round(avg(case when is_late is true then 0
                   when is_late is false then 1 end), 3)     as on_time_rate
from {{ ref('fct_orders') }}
where is_valid_revenue
group by purchase_month
