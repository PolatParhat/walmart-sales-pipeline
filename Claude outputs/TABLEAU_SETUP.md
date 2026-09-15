# Building the Tableau dashboard from GOLD.SALES_REPORT

This walks through connecting Tableau to Snowflake and rebuilding each
view from your reference dashboard, using the single Gold table
(`WALMART_DEV.GOLD.SALES_REPORT`) built earlier.

## 0. Tableau basics, since this is your first time

A few concepts before touching anything - these apply to every chart in
this guide, not just the first one.

**Dimensions vs. Measures.** When you connect to a table, Tableau splits
every column into two lists in the **Data pane** on the left: blue pills
under **Dimensions** (categories/labels you group or slice by - things
like `store_id`, `is_holiday`, `store_type`, dates) and green pills under
**Measures** (numbers you aggregate - `store_weekly_sales`, `fuel_price`,
`cpi`). Tableau guesses this split from the data type, and it's usually
right, but you can drag a field from one list to the other if it guessed
wrong (e.g. it might treat `store_id` as a number/Measure since it's
numeric - drag it up into Dimensions, since you want to group by it, not
sum it).

**Shelves.** The workspace has a **Columns** shelf and a **Rows** shelf
running along the top of the canvas. Dragging a field onto one of these
is what actually builds the chart - a dimension on Columns and a measure
on Rows gives you a bar chart by default, for example. This is the core
interaction in Tableau: almost everything is drag-a-field-from-the-Data-
pane-onto-a-shelf.

**The Marks card.** To the left of the canvas, this controls how each
data point is drawn - drag a field onto **Color** to color-code by it,
onto **Size**, onto **Label** to show its value as text, onto **Detail**
to add it to the chart without any visual encoding (useful for keeping a
tooltip informative). There's also a dropdown at the top of the Marks
card (Automatic / Bar / Line / Circle / etc.) to force a specific chart
type.

**Aggregation.** When you drag a measure like `store_weekly_sales` onto a
shelf, Tableau automatically wraps it as `SUM(store_weekly_sales)` -
you'll see the field's pill say exactly that. Right-click the pill on the
shelf -> **Measure (Sum)** to change it to `AVG`, `MIN`, `MAX`, `COUNT`,
etc. This is where the `SUM` vs `AVG` choice mentioned in the caveat
below actually gets made.

**Sheets vs. Dashboards.** Each individual chart lives on its own
**Sheet** (the tabs at the bottom, like tabs in a spreadsheet). A
**Dashboard** is a separate kind of tab that combines multiple sheets
into one combined view - that's the thing that actually looks like your
reference screenshots. Build each chart on its own sheet first, then
assemble them onto a dashboard at the end (Section 5).

## 1. Connect Tableau to Snowflake

1. Open Tableau Desktop. You land on the **Start page**, with a
   **Connect** panel on the left listing connection types.
2. Under "To a Server," click **Snowflake** (if you don't see it in the
   short list, click "More..." to find it).
3. A connection dialog pops up. Fill in:

   | Field | Value |
   |---|---|
   | Server | `<your_account_locator>.snowflakecomputing.com` (same one from `SETUP.md`) |
   | Warehouse | `REPORT_WH` |
   | Database | `WALMART_DEV` |
   | Schema | `GOLD` |
   | Role | `WALMART_REPORTER` |
   | Authentication | Username/Password (or key-pair if you'd rather not type a password each session - Tableau supports it, but username/password is simpler to start with) |

4. Click **Sign In**. You'll land on the **Data Source page** - a mostly
   empty canvas with a list of schemas/tables on the left.
5. On the left, under the `GOLD` schema, find `SALES_REPORT` and
   **drag it onto the canvas** in the middle. A preview of the table's
   rows appears below - that confirms the connection actually works and
   Tableau can see your data.
6. At the top of this page, there's a toggle for **Live** vs.
   **Extract**. Leave it on **Live** - `REPORT_WH` is XSMALL with a 60s
   auto-suspend, so it's cheap to query on demand, and a live connection
   means the dashboard always reflects whatever dbt last built, with no
   separate refresh step to remember.
7. Click the **Sheet 1** tab at the bottom of the window. This is where
   you'll build your first chart.

`WALMART_REPORTER` is already set up for exactly this: read-only on
`GOLD`, no visibility into `RAW` or `SILVER` at all. `07_roles_and_grants.sql`
already granted it to your own Snowflake user for testing, and its
`GRANT SELECT ON FUTURE TABLES IN SCHEMA GOLD` means `SALES_REPORT` is
automatically covered even though it didn't exist when that grant was
first run.

## 2. Columns available on SALES_REPORT

For reference while building the sheets below:

`store_id`, `dept_id`, `date_id`, `store_date`, `sales_year`,
`sales_month`, `is_holiday`, `store_type`, `store_size`,
`store_weekly_sales`, `fuel_price`, `temperature`, `unemployment`, `cpi`,
`markdown1`-`markdown5`.

## 3. Important caveat before you start aggregating

`SALES_REPORT` is at the **store + dept + week** grain - one row per
department, per store, per week. But `fuel_price`, `temperature`, `cpi`,
`unemployment`, and the `markdown1`-`5` columns are only meaningful at
the **store + week** level (this is inherent to the original dataset, not
something this pipeline introduced) - the same fuel price value repeats
across every department row for that store/week.

That means `SUM(fuel_price)` grouped by store/year will add up the same
number once per department - a store with 40 departments will show a
fuel price total ~40x too large. Your reference screenshots do show
large, summed values for these ("1.42M Fuel_Price", "25.33M Temperature")
- if you want to match those exact numbers, use `SUM()` as shown below;
if you want a figure that's actually meaningful as a fuel price or
temperature, use `AVG()` instead. I've noted both options per chart
where it matters.

## 4. Chart-by-chart setup

### Weekly sales by store and holiday (worked example, step by step)

This is the same chart as the shorthand two paragraphs down - built out
in full first-timer detail so you can see the whole rhythm once.

**The bar chart:**

1. On Sheet 1, find `store_id` in the Data pane on the left (under
   Dimensions - drag it up there first if Tableau put it under Measures,
   since it's an ID, not a quantity to sum). Drag it onto the **Columns**
   shelf at the top of the canvas. You'll see one column per store
   appear, currently empty.
2. Find `store_weekly_sales` under Measures. Drag it onto the **Rows**
   shelf. Bars appear immediately - Tableau default-aggregates it as
   `SUM(store_weekly_sales)` (you'll see the pill on the Rows shelf
   literally say that).
3. Find `is_holiday` under Dimensions. Drag it onto **Color** in the
   Marks card (to the left of the canvas). The bars split into two
   colors per store - holiday weeks vs. non-holiday weeks.
4. Rename the sheet: double-click the "Sheet 1" tab at the bottom and
   type something like `Weekly Sales by Store and Holiday`.

**The pie chart** (build it on a new sheet - right-click any sheet tab
at the bottom -> **New Worksheet**):

1. Drag `store_weekly_sales` onto the canvas area (not a shelf - just
   drop it in the middle). Tableau defaults to a bar; that's fine for
   now.
2. In the Marks card dropdown (says "Automatic" by default), change it
   to **Pie**.
3. Drag `is_holiday` onto **Color**, and also onto **Angle** if it's not
   already driving the slice sizes (drag `store_weekly_sales` onto
   **Angle** specifically if the pie doesn't size itself correctly).

**The KPI tiles** (one more new sheet):

1. Drag `store_weekly_sales` onto the canvas.
2. In the Marks card dropdown, choose **Text** (sometimes labeled
   "Shape" -> Text, depending on version) - this gives you one big
   number instead of a chart.
3. Increase the font size via the **Label** button in the Marks card, or
   by clicking the text on the canvas and using Format -> Font, to make
   it read like a tile rather than a table cell.

Once you've done this once, every other chart below is the same
motion repeated: drag a dimension to Columns/Rows/Color, drag a measure
to Rows/Angle/Text, pick a mark type. The rest of this guide is written
in shorthand assuming that rhythm.

### Weekly sales by temperature and year

### Weekly sales by temperature and year

- Columns = `temperature` (as a continuous dimension, or bin it), Rows = `SUM(store_weekly_sales)`, Color/Legend = `sales_year`.
- KPI: `MIN(store_date)` for "Earliest Date"; `SUM(temperature)` (or `AVG(temperature)` - see caveat above) for the temperature tile.

### Weekly sales by store size

- Columns = `store_size` (continuous), Rows = `SUM(store_weekly_sales)`.
- Table: `store_id`, `store_size`, `SUM(store_weekly_sales)`, sorted descending on sales.

### Weekly sales by store type and month

- Columns = `sales_month`, Rows = `SUM(store_weekly_sales)`, Color = `store_type`.
- Crosstab version: Rows = `sales_month`, Columns = `store_type`, Text = `SUM(store_weekly_sales)`.

### Markdown sales by year and store

- Table: Rows = `store_id`, Columns = `sales_year` (as a filter/parameter to page through years), Text = `SUM(markdown1)` through `SUM(markdown5)` as separate columns.
- Bar chart: Columns = `sales_year`, Rows = `SUM(markdown1)`...`SUM(markdown5)` (measure names/values pivoted onto one axis, colored by measure).
- Add `sales_year` as a **filter** (or a parameter driving a calculated field) to reproduce the "select year" control.

### Weekly sales by store type

- Quick filter: `store_type` as a filter control (checkboxes for A/B/C).
- Pie: Angle = `SUM(store_weekly_sales)`, Color = `store_type`.
- Horizontal bar: Rows = `store_type` then `store_id` (nested), Columns = `SUM(store_weekly_sales)`.

### Fuel price by year

- Table: Rows = `store_id`, Columns = `sales_year`, Text = `SUM(fuel_price)` (or `AVG(fuel_price)` - see caveat), with a Grand Total column/row turned on (Analysis -> Totals).
- Donut: Angle = `SUM(fuel_price)`, Color = `sales_year`.
- KPI: `SUM(fuel_price)` (or `AVG`) as a single big number.

### Weekly sales by year, month, and date

- Three views sharing the same measure: Columns = `sales_year` → bar; Columns = `sales_month` → bar; Columns = `store_date` (as a continuous date, day-level) → bar. Rows = `SUM(store_weekly_sales)` on all three.

### Weekly sales by CPI

- Columns = `cpi`, Rows = `SUM(store_weekly_sales)` (or plot at row-level detail without aggregation for a true scatter - drag `cpi` and `store_weekly_sales` both to Columns/Rows as continuous fields, no aggregation, for a proper scatter plot rather than a sum-by-bucket).

### Department-wise weekly sales

- Table: Rows = `dept_id`, Text = `SUM(store_weekly_sales)`.
- KPI: `SUM(store_weekly_sales)` total.
- Top 5: same table, sorted descending, filtered to Top 5 by `SUM(store_weekly_sales)` (right-click the `dept_id` field on Rows -> Sort, or use a Top N filter).
- Bar: Columns = `dept_id`, Rows = `SUM(store_weekly_sales)`, Color = `dept_id`.

## 5. Assembling the dashboard

Create a new **Dashboard**, drag each sheet in, and use Tableau's
dashboard actions (Dashboard -> Actions -> Filter) so that clicking a
mark on one chart (say, a store in the store-size chart) filters the
others - this is what makes it read as one dashboard instead of a
collection of separate charts, matching the multi-panel layout in your
reference screenshots.
