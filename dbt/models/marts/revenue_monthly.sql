-- Monthly revenue trend — a CURATED reporting mart. Olist's usable window is
-- 2017-01 … 2018-08; the edge months are dataset ramp-up + a 2018-09 data-cutoff
-- stub (~297 orders total) that fake a cliff. We trim them HERE so the series is
-- correct by default — no downstream consumer has to remember a filter.
-- (fct_orders keeps every order for auditability; cleaning lives at the layer
--  that matches each table's purpose.)
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
  and purchase_month between date('2017-01-01') and date('2018-08-01')
group by purchase_month
