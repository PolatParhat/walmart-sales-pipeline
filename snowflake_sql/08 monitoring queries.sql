 USE DATABASE WALMART_DEV;
 USE SCHEMA RAW;


-- 1) Quick health check: is the pipe running, and does it have files
-- queued/pending right now? Good for "is something stuck".
SELECT SYSTEM$PIPE_STATUS('WALMART_DEV.RAW.STORES_PIPE');
SELECT SYSTEM$PIPE_STATUS('WALMART_DEV.RAW.DEPARTMENT_PIPE');
SELECT SYSTEM$PIPE_STATUS('WALMART_DEV.RAW.FACT_PIPE');



-- 2) The real answer to "did it load": per-file load history for one
-- table. Shows LOADED / LOAD_FAILED / PARTIALLY_LOADED per file, rows
-- parsed vs loaded, and the actual error message if something failed.
-- This is live (not the ~2hr-latency ACCOUNT_USAGE views below), so use
-- this one right after uploading a test file.
SELECT *
FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
  TABLE_NAME => 'WALMART_DEV.RAW.STORES_RAW',
  START_TIME => DATEADD(HOURS, -24, CURRENT_TIMESTAMP())
))
ORDER BY LAST_LOAD_TIME DESC;
 
SELECT *
FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
  TABLE_NAME => 'WALMART_DEV.RAW.FACT_RAW',
  START_TIME => DATEADD(HOURS, -24, CURRENT_TIMESTAMP())
))
ORDER BY LAST_LOAD_TIME DESC;
 
SELECT *
FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
  TABLE_NAME => 'WALMART_DEV.RAW.DEPARTMENT_RAW',
  START_TIME => DATEADD(HOURS, -24, CURRENT_TIMESTAMP())
))
ORDER BY LAST_LOAD_TIME DESC;




-- 3) Same load history, but all three pipes in one query instead of
-- one call per table. Backed by ACCOUNT_USAGE, so it can lag up to
-- ~2 hours behind real time - don't use this one to debug something
-- that just happened seconds ago, use #2 for that.
SELECT pipe_name, file_name, status, row_count, row_parsed,
       first_error_message, last_load_time
FROM SNOWFLAKE.ACCOUNT_USAGE.COPY_HISTORY
WHERE pipe_name IN ('STORES_PIPE', 'FACT_PIPE', 'DEPARTMENT_PIPE')
ORDER BY last_load_time DESC
LIMIT 50;
 
-- 4) Simplest possible check - if the row count went up, it loaded.
SELECT COUNT(*) FROM WALMART_DEV.RAW.STORES_RAW;
SELECT COUNT(*) FROM WALMART_DEV.RAW.FACT_RAW;
SELECT COUNT(*) FROM WALMART_DEV.RAW.DEPARTMENT_RAW;
 
-- 5) Snowpipe compute cost - this runs on Snowflake-managed serverless
-- compute billed separately from your warehouses (see 06_warehouses.sql),
-- worth glancing at occasionally. Same ~2hr ACCOUNT_USAGE latency as #3.
SELECT pipe_name, SUM(credits_used) AS credits_used
FROM SNOWFLAKE.ACCOUNT_USAGE.PIPE_USAGE_HISTORY
WHERE start_time >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
GROUP BY pipe_name;

 SELECT * FROM STORES_RAW;
 SELECT * FROM DEPARTMENT_RAW;
 SELECT * FROM FACT_RAW;

-- After the running the dbt --select staging
SELECT * FROM SILVER.STG_DEPARTMENT;
SELECT * FROM SILVER.STG_FACT;
SELECT * FROM SILVER.STG_STORES;

SELECT * FROM SILVER.STORE_DIM;
SELECT * FROM SILVER.DATE_DIM;

SELECT * FROM SILVER.INT_SALES_COMBINED;
SELECT * FROM SILVER.snap_sales;

SELECT * FROM SILVER.SALES_FACT;
SELECT * FROM GOLD.SALES_REPORTS WHERE SALES_YEAR BETWEEN 2010 AND 2013;