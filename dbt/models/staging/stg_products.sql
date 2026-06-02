-- Join the PT→EN category translation; fix the source's "lenght" misspelling.
select
    p.product_id,
    p.product_category_name                         as category_pt,
    coalesce(t.product_category_name_english,
             p.product_category_name, 'unknown')    as category,
    p.product_name_lenght                           as name_length,
    p.product_description_lenght                    as description_length,
    p.product_photos_qty                            as photos_qty,
    p.product_weight_g                              as weight_g
from {{ source('raw', 'products') }} p
left join {{ source('raw', 'category_translation') }} t
    on p.product_category_name = t.product_category_name
