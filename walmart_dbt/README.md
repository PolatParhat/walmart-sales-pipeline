# Walmart pipeline — dbt project (Silver + Gold)

## Setup

See `SETUP.md` for the full walkthrough (key-pair auth, profiles.yml
placement, troubleshooting). Short version once that's done:

```bash
dbt debug
dbt build
```

This connects as `WALMART_TRANSFORMER` on `TRANSFORM_WH` - the exact
role/warehouse created in `07_roles_and_grants.sql` / `06_warehouses.sql`.

## Run order

```bash
dbt debug          # confirms the connection works before anything else
dbt source freshness   # optional - checks RAW hasn't gone stale
dbt run --select staging       # builds stg_stores, stg_fact, stg_department
dbt run --select store_dim date_dim   # SCD1 dimensions
dbt run --select intermediate  # builds int_sales_combined
dbt snapshot        # builds/updates snap_sales (the actual SCD2 mechanics)
dbt run --select sales_fact sales_report   # SCD2 presentation + Gold report
dbt test            # not_null / unique / relationships checks
```

Or just `dbt build` to run models, snapshots, and tests together in
dependency order (note: `dbt build` runs snapshots in the same DAG pass,
so this is the simpler day-to-day command once you trust the pipeline).

## Structure

This follows dbt Labs' actual documented three-layer project convention -
`staging/`, `intermediate/`, and `marts/`, each flat (no subfolders; dbt
Labs reserves those for grouping by business domain once a layer has
~10+ models, and none of these do yet):

- `models/staging/` - one model per raw table, 1:1 with `stores_raw`,
  `fact_raw`, `department_raw`. Only job: dedupe (same problem discussed
  for Raw - duplicate rows across files) and light renaming. Materialized
  as views. Lands in the `SILVER` schema (inherited from `profiles.yml`'s
  default schema - no override needed).
- `models/intermediate/int_sales_combined.sql` - joins department
  (weekly_sales) with fact (fuel price, temperature, CPI, unemployment,
  markdowns) and store (`store_size`, denormalized onto the fact per
  spec), and looks up `date_id` from `date_dim` so downstream tables
  reference the surrogate key instead of a raw date. Lands at the
  store+dept+date_id grain. dbt Labs' convention: intermediate models
  "prepare staging models for marts" - business logic and joins that
  aren't yet a business-defined entity on their own, named with the
  `int_` prefix, in their own folder. Materialized as a view (not
  ephemeral, so it stays independently runnable/testable). Feeds the
  snapshot; not meant to be queried directly. Lands in `SILVER`.
- `models/marts/store_dim.sql` - SCD1, incremental merge. Grain is
  `(store_id, dept_id)` per the finalized spec, not store alone -
  `store_type`/`store_size` are store-level attributes that repeat across
  every dept row for the same store (intentional denormalization).
  `date_dim.sql` is likewise SCD1/incremental merge, grain `date_id`. Both:
  a changed row overwrites in place, `insert_date` is preserved via
  `merge_exclude_columns`, `update_date` refreshes on every change. Both
  land in `SILVER`.
- `snapshots/snap_sales.sql` - the actual SCD2 versioning, using dbt's
  built-in snapshot feature, keyed on `store_id || dept_id || date_id`.
  dbt's own column names (`dbt_valid_from`, `dbt_valid_to`) aren't
  configurable, which is why `sales_fact.sql` exists on top of it.
  Snapshots always live in their own top-level `snapshots/` folder - this
  is a hard dbt requirement, not a medallion-layer choice.
- `models/marts/sales_fact.sql` - presentation layer, renames the
  snapshot's columns to match the finalized `Walmart_fact_table` spec
  (`vrsn_start_date`, `vrsn_end_date`, `store_weekly_sales`) and carries
  `date_id`/`store_size` through. Full column list: `store_id`, `dept_id`,
  `date_id`, `store_size`, `store_weekly_sales`, `fuel_price`,
  `temperature`, `unemployment`, `cpi`, `markdown1`-`markdown5`,
  `vrsn_start_date`, `vrsn_end_date`, `insert_date`, `update_date`.
  Lands in `SILVER`.
- `models/marts/sales_report.sql` - see "Gold layer" below. Lands in
  `GOLD`.

## How this maps onto Raw / Silver / Gold

dbt's three layers line up with a medallion architecture more directly
than earlier notes here suggested:

| Medallion layer | dbt folder | What happens there |
|---|---|---|
| Bronze/Raw | (Snowflake `RAW` schema - upstream of dbt entirely) | Landing, no transformation |
| Silver | `models/staging/` + `models/intermediate/` | Clean/dedupe (staging), then join/prep business logic (intermediate) |
| Silver (dimensional model) | `models/marts/store_dim.sql`, `date_dim.sql`, `sales_fact.sql` | Final fact/dim tables - conformed and business-defined, but still grain-level detail |
| Gold | `models/marts/sales_report.sql` | Aggregation-ready, denormalized, BI-facing |

What actually decides which Snowflake schema a model lands in is the
`+schema` (or default) config, not the folder name: `staging/`,
`intermediate/`, and most of `marts/` all target `SILVER` via the default
schema in `profiles.yml`; `sales_report.sql` is the one exception,
overriding to `GOLD` via its own `config()` block (see "Gold layer").

## Why a separate snapshot + presentation model instead of one model

dbt snapshots are the only built-in mechanism for "keep every historical
version of a row," and they're intentionally rigid about their own schema
(fixed column names, append-only target table) so that history can never
be silently rewritten by a model change. Wrapping a plain `select` on top
lets the rest of the project (Gold models, Tableau) see clean column
names without touching how the history itself is captured or stored.

## Gold layer

`models/marts/sales_report.sql` is a single wide, denormalized table for
Tableau - one row per current store+dept+week (`sales_fact` filtered to
`vrsn_end_date is null`, so SCD2 history isn't double-counted), joined to
`date_dim` (for `store_date`/`sales_year`/`sales_month`/`is_holiday`) and
`store_dim` (for `store_type`). Deliberately one wide table instead of
several narrow pre-aggregated ones: Tableau does its own grouping/pivoting
at query time, and some views (sales vs. CPI, markdowns by year/store)
need row-level detail a pre-summed table would have already lost.

It stays flat alongside the Silver dims/fact rather than getting its own
`gold/` subfolder - dbt Labs' guidance reserves marts subfolders for
grouping by business domain once a project has enough marts, not for
technical reasons like a different schema target. Instead,
`sales_report.sql` sets its own `+schema: GOLD` locally via a `config()`
block in the file. `macros/generate_schema_name.sql` overrides dbt's
default behavior of *appending* a model's `+schema` onto the target
schema (which would otherwise produce `SILVER_GOLD`, not `GOLD`) so it's
used literally.
