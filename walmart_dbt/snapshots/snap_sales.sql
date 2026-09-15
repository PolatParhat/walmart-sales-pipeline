-- This is where SCD2 actually happens. dbt's snapshot feature is built
-- specifically for this: every time it runs, it compares the incoming
-- row (keyed by store_id+dept_id+date_id) against the current version in
-- SNAP_SALES, and if _loaded_at is newer, closes out the old version
-- (sets dbt_valid_to) and inserts a new one (dbt_valid_from = now).
-- Unchanged rows are left alone entirely.
--
-- Keyed on date_id (not the raw date) because int_sales_combined now
-- carries date_id instead of date - the fact table references the
-- date_dim surrogate key per the finalized spec.
--
-- dbt fixes the column names it adds (dbt_valid_from, dbt_valid_to,
-- dbt_scd_id, dbt_updated_at) - they aren't configurable here. sales_fact.sql
-- renames them to match the vrsn_start_date/vrsn_end_date naming from the
-- original dimension model spec.

{% snapshot snap_sales %}

{{
    config(
        target_schema='SILVER',
        unique_key="store_id || '-' || dept_id || '-' || date_id",
        strategy='timestamp',
        updated_at='_loaded_at',
    )
}}

select * from {{ ref('int_sales_combined') }}

{% endsnapshot %}
