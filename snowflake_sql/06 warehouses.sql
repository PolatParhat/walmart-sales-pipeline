USE ROLE sysadmin;

CREATE WAREHOUSE IF NOT EXISTS LOAD_WH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = 'Manual COPY INTO / ad hoc raw-layer testing. Snowpipe auto-ingest itself runs on Snowflake-managed serverless compute, billed separately - it does not use this warehouse.';


  CREATE WAREHOUSE IF NOT EXISTS TRANSFORM_WH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = 'dbt runs - builds SILVER and GOLD models.';
 
CREATE WAREHOUSE IF NOT EXISTS REPORT_WH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = 'Tableau queries against GOLD only.';