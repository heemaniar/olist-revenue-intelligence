-- Product dimension: id + English category and a few physical attributes.
select
    product_id,
    category,
    category_pt,
    weight_g,
    photos_qty
from {{ ref('stg_products') }}
