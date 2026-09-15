-- Single wide, denormalized Gold table for Tableau - one row per
-- store+dept+week, with every dimension attribute and measure flattened
-- onto it. This is deliberately NOT a set of narrow pre-aggregated tables
-- (e.g. "sales by holiday", "sales by store size") - Tableau does that
-- grouping/pivoting itself at query time, and several views (weekly sales
-- vs. CPI, markdowns by year and store) need row-level detail that a
-- pre-summed table would have already thrown away.
--
-- Filters to current-version rows only (vrsn_end_date is null): sales_fact
-- is SCD2 and holds every historical version of a row. Without this
-- filter, any store/dept/week that was ever corrected would be summed
-- twice by Tableau - once for the old version, once for the new one.
--
-- store_type comes from store_dim (not on sales_fact); store_size is
-- already denormalized onto sales_fact per the original spec, so it's
-- taken from there directly rather than re-joining for it.
--
-- Flat in models/marts/ alongside the Silver dims/fact - dbt Labs' own
-- guidance is to subdivide marts by business domain once you have ~10+ of
-- them, not by a technical reason like schema target. This project has 5
-- marts total, so a subfolder isn't earned yet either way. The GOLD
-- schema target is handled locally instead, via the config() below.

{{ config(schema='GOLD') }}

select
    f.store_id,
    f.dept_id,
    f.date_id,
    d.store_date,
    year(d.store_date)  as sales_year,
    month(d.store_date) as sales_month,
    d.is_holiday,
    sd.store_type,
    f.store_size,
    f.store_weekly_sales,
    f.fuel_price,
    f.temperature,
    f.unemployment,
    f.cpi,
    f.markdown1,
    f.markdown2,
    f.markdown3,
    f.markdown4,
    f.markdown5,
    f.vrsn_start_date,
    f.vrsn_end_date
from {{ ref('sales_fact') }} f
left join {{ ref('date_dim') }} d
    on f.date_id = d.date_id
left join {{ ref('store_dim') }} sd
    on f.store_id = sd.store_id
    and f.dept_id = sd.dept_id
where f.vrsn_end_date is null
