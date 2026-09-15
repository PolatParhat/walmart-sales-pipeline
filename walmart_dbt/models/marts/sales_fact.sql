-- Presentation layer on top of the snapshot - renames dbt's fixed SCD2
-- column names to match the finalized Walmart_fact_table spec
-- (vrsn_start_date/vrsn_end_date), and carries date_id/store_size through
-- from int_sales_combined so this matches the spec's exact column list:
-- Store_id, Dept_id, Date_id, Store_size, Store_weekly_sales, Fuel_price,
-- Temperature, un-employment, CPI, Markdown1-5, vrsn_start_date,
-- vrsn_end_date, insert_date, update_date.
--
-- Note: column is "temperature" here, not "store_temperature" - the
-- finalized spec just says "Temperature" (no earlier discussion of a
-- Store_ prefix carried over to this table). Rename if you'd rather keep
-- it consistent with the Store_weekly_sales-style naming used elsewhere.
--
-- Note: insert_date/update_date are somewhat redundant with
-- vrsn_start_date/vrsn_end_date on a versioned table like this - every
-- "version" of a row already carries its own start/end. Kept here to
-- match the spec; worth deciding later whether you want both pairs of
-- columns long-term or just the vrsn_* ones.

select
    store_id,
    dept_id,
    date_id,
    store_size,
    weekly_sales as store_weekly_sales,
    fuel_price,
    temperature,
    unemployment,
    cpi,
    markdown1,
    markdown2,
    markdown3,
    markdown4,
    markdown5,
    dbt_valid_from as vrsn_start_date,
    dbt_valid_to as vrsn_end_date,
    dbt_valid_from as insert_date,
    coalesce(dbt_valid_to, dbt_valid_from) as update_date
from {{ ref('snap_sales') }}
