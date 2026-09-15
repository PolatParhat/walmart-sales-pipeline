-- One row per (store_id, dept_id, date) - the grain the fact table is
-- ultimately built at.

with source as (
    select * from {{ source('raw', 'department_raw') }}
),

deduped as (
    select
        store_id,
        dept_id,
        date,
        weekly_sales,
        is_holiday,
        _loaded_at,
        row_number() over (
            partition by store_id, dept_id, date
            order by _loaded_at desc
        ) as rn
    from source
    where store_id is not null
      and dept_id is not null
      and date is not null
)

select
    store_id,
    dept_id,
    date,
    weekly_sales,
    is_holiday,
    _loaded_at
from deduped
where rn = 1