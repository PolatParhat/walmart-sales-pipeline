with source as(
  select * from {{ source('raw', 'stores_raw') }}
),
deduped as (
  select 
    store_id,
    store_type,
    store_size,
    _loaded_at,
    row_number() over (
      partition by store_id
      order by _loaded_at desc
    ) as rn
    from source where store_id is not null
)

select
  store_id,
  store_type,
  store_size,
  _loaded_at
from deduped
where rn = 1