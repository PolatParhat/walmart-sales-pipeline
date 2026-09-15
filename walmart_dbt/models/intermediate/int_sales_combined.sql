-- Fans out store-date-level attributes (fuel price, temperature, CPI,
-- unemployment, markdowns) from stg_fact onto every department at that
-- store/date, joins in store_size from stg_stores (denormalized onto the
-- fact per the finalized spec), and looks up date_id from date_dim so the
-- fact table references the surrogate key instead of a raw date. This is
-- the row set that gets versioned by the snapshot below.
--
-- The date_dim join is LEFT, not INNER, on purpose: an INNER join would
-- silently drop any row whose date isn't in date_dim yet (e.g. if this
-- ever ran out of order relative to date_dim). LEFT join + the not_null
-- test on date_id in _marts__schema.yml means a missing date_dim entry
-- shows up as a loud test failure instead of quietly vanishing rows.

select
    d.store_id,
    d.dept_id,
    dd.date_id,
    s.store_size,
    d.weekly_sales,
    f.fuel_price,
    f.temperature,
    f.unemployment,
    f.cpi,
    f.markdown1,
    f.markdown2,
    f.markdown3,
    f.markdown4,
    f.markdown5,
    greatest(d._loaded_at, coalesce(f._loaded_at, d._loaded_at)) as _loaded_at
from {{ ref('stg_department') }} d
left join {{ ref('stg_fact') }} f
    on d.store_id = f.store_id
    and d.date = f.date
left join {{ ref('stg_stores') }} s
    on d.store_id = s.store_id
left join {{ ref('date_dim') }} dd
    on d.date = dd.store_date
