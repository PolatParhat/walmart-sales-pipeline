-- SCD1 date dimension. Dates and their is_holiday flag come from both
-- feature-level and department-level source data (both carry it), so we
-- union and dedupe rather than assuming either source alone is complete.
-- date_id is a YYYYMMDD integer surrogate key (standard Kimball pattern).

{{
    config(
        materialized='incremental',
        unique_key='date_id',
        incremental_strategy='merge',
        merge_exclude_columns=['insert_date']
    )
}}

with dates as (
    select date, is_holiday, _loaded_at from {{ ref('stg_fact') }}
    union all
    select date, is_holiday, _loaded_at from {{ ref('stg_department') }}
),

deduped as (
    select
        date,
        is_holiday,
        _loaded_at,
        row_number() over (partition by date order by _loaded_at desc) as rn
    from dates
)

select
    to_number(to_char(date, 'YYYYMMDD')) as date_id,
    date as store_date,
    is_holiday,
    _loaded_at,
    current_timestamp() as insert_date,
    current_timestamp() as update_date
from deduped
where rn = 1

{% if is_incremental() %}
and _loaded_at > (
    select coalesce(max(update_date), '1900-01-01'::timestamp_ntz) from {{ this }}
)
{% endif %}
