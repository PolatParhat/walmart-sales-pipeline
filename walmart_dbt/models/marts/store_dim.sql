-- SCD1: incremental merge on the composite key (store_id, dept_id).
-- Grain changed from "one row per store" to "one row per store+dept
-- combination" per the finalized spec - store_type/store_size are
-- store-level attributes, so they repeat across every department row
-- for the same store. That's intentional denormalization, not a bug.
--
-- dept_id only exists in the department-level source data (stores.csv
-- never had it), so the distinct store+dept combinations come from
-- stg_department, joined back to stg_stores for the store attributes.

{{
    config(
        materialized='incremental',
        unique_key=['store_id', 'dept_id'],
        incremental_strategy='merge',
        merge_exclude_columns=['insert_date']
    )
}}

with store_depts as (
    select
        store_id,
        dept_id,
        max(_loaded_at) as _loaded_at
    from {{ ref('stg_department') }}
    group by store_id, dept_id
),

joined as (
    select
        sd.store_id,
        sd.dept_id,
        s.store_type,
        s.store_size,
        greatest(sd._loaded_at, s._loaded_at) as _loaded_at
    from store_depts sd
    inner join {{ ref('stg_stores') }} s
        on sd.store_id = s.store_id
)

select
    store_id,
    dept_id,
    store_type,
    store_size,
    _loaded_at,
    current_timestamp() as insert_date,
    current_timestamp() as update_date
from joined

{% if is_incremental() %}
where _loaded_at > (
    select coalesce(max(update_date), '1900-01-01'::timestamp_ntz) from {{ this }}
)
{% endif %}
