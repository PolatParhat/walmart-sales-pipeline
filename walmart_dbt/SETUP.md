# dbt Core setup guide

## 1. Confirm the install

```bash
dbt --version
```

You need both `dbt-core` and the `dbt-snowflake` adapter listed. If
`dbt-snowflake` is missing:

```bash
pip install dbt-snowflake
```

(installing the adapter pulls in the matching dbt-core version
automatically - you don't need `dbt-core` as a separate install)

## 2. Set up key-pair authentication

`profiles.yml.example` uses key-pair auth (`SNOWFLAKE_JWT`) instead of a
password - the same auth method you'd want later for CI or Airflow, since
neither can type a password interactively.

Generate the key pair:

```bash
mkdir -p ~/.ssh
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out ~/.ssh/snowflake_rsa_key.p8 -nocrypt
openssl rsa -in ~/.ssh/snowflake_rsa_key.p8 -pubout -out ~/.ssh/snowflake_rsa_key.pub
chmod 600 ~/.ssh/snowflake_rsa_key.p8
```

Copy the contents of `snowflake_rsa_key.pub` (everything between the
`BEGIN`/`END PUBLIC KEY` lines, no line breaks) and register it against
your Snowflake user:

```sql
ALTER USER <your_snowflake_username> SET RSA_PUBLIC_KEY='<paste key body here>';
```

Verify it took:

```sql
DESC USER <your_snowflake_username>;
-- RSA_PUBLIC_KEY_FP should now show a fingerprint instead of being empty
```

## 3. Confirm your user has WALMART_TRANSFORMER

```sql
SHOW GRANTS TO USER <your_snowflake_username>;
```

Should list `WALMART_TRANSFORMER`. If it's missing, re-run the relevant
`GRANT ROLE ... TO USER ...` line from `07_roles_and_grants.sql`.

## 4. Lay out the project folder

Folder structure matters - dbt discovers models by path, not by a
manifest you maintain:

```
walmart_dbt/
  dbt_project.yml
  profiles.yml.example
  README.md
  SETUP.md
  macros/
    generate_schema_name.sql
  models/
    staging/
      _staging__sources.yml
      stg_stores.sql
      stg_department.sql
      stg_fact.sql
    intermediate/
      _int_sales__models.yml
      int_sales_combined.sql
    marts/
      _marts__schema.yml
      store_dim.sql
      date_dim.sql
      sales_fact.sql
      sales_report.sql
  snapshots/
    snap_sales.sql
```

This is dbt Labs' actual documented three-layer convention - `staging/`,
`intermediate/`, and `marts/` as top-level siblings, each kept flat
rather than split into further subfolders (dbt Labs reserves that for
grouping by business domain once a layer has ~10+ models - none of these
do yet). `staging/`, `intermediate/`, and most of `marts/` land in the
`SILVER` schema (see README's "How this maps onto Raw / Silver / Gold"
section); `sales_report.sql` is the one exception, targeting `GOLD` via
its own `config()` block plus the `generate_schema_name` macro override.

## 5. Set up profiles.yml

This file holds connection details and lives **outside** the project
folder by dbt convention, specifically so credentials never end up
committed to Git alongside your models:

```bash
mkdir -p ~/.dbt
cp walmart_dbt/profiles.yml.example ~/.dbt/profiles.yml
```

Edit `~/.dbt/profiles.yml` and fill in your account locator - find it in
the Snowflake URL when you're logged into Snowsight
(`https://<account_locator>.snowflakecomputing.com`), or run
`SELECT CURRENT_ACCOUNT(), CURRENT_REGION();` in a worksheet.

Set the two env vars the file references (add them to `~/.bashrc` or
`~/.zshrc` so they persist across terminal sessions, not just this one):

```bash
export SNOWFLAKE_USER=<your_snowflake_username>
export SNOWFLAKE_PRIVATE_KEY_PATH=~/.ssh/snowflake_rsa_key.p8
```

## 6. Verify the connection

```bash
cd walmart_dbt
dbt debug
```

Should end with "All checks passed!". If not, see Troubleshooting below.

## 7. First run

```bash
dbt run --select staging
dbt run --select store_dim date_dim
dbt run --select int_sales_combined
dbt snapshot
dbt run --select sales_fact
dbt run --select sales_reports.sql
dbt test
```

Once you trust it end to end, `dbt build` runs all of the above together
in dependency order.

## Troubleshooting

**JWT / "could not connect" errors** - the registered public key doesn't
match the private key path in `profiles.yml`, or the key body was pasted
with extra whitespace/line breaks. Compare fingerprints:

```bash
openssl rsa -pubin -in ~/.ssh/snowflake_rsa_key.pub -outform DER | openssl dgst -sha256 -binary | openssl enc -base64
```

against `RSA_PUBLIC_KEY_FP` from `DESC USER`.

**"Object does not exist or not authorized" on a RAW table** -
`WALMART_TRANSFORMER` doesn't have `SELECT` on `RAW`, or wasn't granted to
your user. Re-check `07_roles_and_grants.sql`.

**"Warehouse 'TRANSFORM_WH' does not exist or not authorized"** - same
idea: re-check the `GRANT USAGE ON WAREHOUSE TRANSFORM_WH TO ROLE
WALMART_TRANSFORMER` line, and that the role itself is granted to you.

**An incremental model (`store_dim`/`date_dim`) behaves oddly on a
retry** - shouldn't happen (`is_incremental()` is false until the table
exists, so the first run is always a full build), but if you need a
clean slate, `DROP TABLE IF EXISTS WALMART_DEV.SILVER.STORE_DIM;` and
re-run.
