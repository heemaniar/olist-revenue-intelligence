-- Per customer state: revenue, delivery speed, on-time, satisfaction.
select
    customer_state                                          as state,
    count(distinct order_id)                                as orders,
    round(sum(gmv), 2)                                      as gmv,
    round(avg(delivery_days), 1)                            as avg_delivery_days,
    round(avg(case when is_late is true then 0
                   when is_late is false then 1 end), 3)    as on_time_rate,
    round(avg(review_score), 2)                             as avg_review
from {{ ref('fct_orders') }}
where is_valid_revenue and customer_state is not null
group by customer_state
