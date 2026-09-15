USE DATABASE WALMART_DEV;
USE SCHEMA RAW;

CREATE TABLE IF NOT EXISTS STORES_RAW (
  store_id     INT,
  store_type   VARCHAR(1),
  store_size   INT,
  _file_name   VARCHAR,
  _row_number  INT,
  _loaded_at   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS FACT_RAW (
  store_id       INT,
  date           DATE,
  temperature    DECIMAL(5,2),
  fuel_price     DECIMAL(6,3),
  markdown1      DECIMAL(10,2),
  markdown2      DECIMAL(10,2),
  markdown3      DECIMAL(10,2),
  markdown4      DECIMAL(10,2),
  markdown5      DECIMAL(10,2),
  cpi            DECIMAL(10,4),
  unemployment   DECIMAL(5,3),
  is_holiday     BOOLEAN,
  _file_name     VARCHAR,
  _row_number    INT,
  _loaded_at     TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);


CREATE TABLE IF NOT EXISTS DEPARTMENT_RAW (
  store_id      INT,
  dept_id       INT,
  date          DATE,
  weekly_sales  DECIMAL(12,2),
  is_holiday    BOOLEAN,
  _file_name    VARCHAR,
  _row_number   INT,
  _loaded_at    TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
 