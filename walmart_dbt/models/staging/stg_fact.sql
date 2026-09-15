-- One row per (store_id, date) - store-level attributes (economic
-- indicators, weather, markdowns) that apply across every department at
-- that store on that date.

with source as (
    select * from {{ source('raw', 'fact_raw') }}
),

deduped as (
    select
        store_id,
        date,
        temperature,
        fuel_price,
        markdown1,
        markdown2,
        markdown3,
        markdown4,
        markdown5,
        cpi,
        unemployment,
        is_holiday,
        _loaded_at,
        row_number() over (
            partition by store_id, date
            order by _loaded_at desc
        ) as rn
    from source
    where store_id is not null
      and date is not null
)

select
    store_id,
    date,
    temperature,
    fuel_price,
    markdown1,
    markdown2,
    markdown3,
    markdown4,
    markdown5,
    cpi,
    unemployment,
    is_holiday,
    _loaded_at
from deduped
where rn = 1