-- SCD1 Test
SELECT * FROM WALMART_DEV.SILVER.STORE_DIM WHERE store_id = 10 AND dept_id = 5;

INSERT INTO WALMART_DEV.RAW.STORES_RAW (store_id, store_type, store_size)
VALUES (10,  'B', 999999);  -- clearly fake value so it's easy to spot

SELECT * FROM WALMART_DEV.RAW.STORES_RAW WHERE store_id = 10;


INSERT INTO WALMART_DEV.RAW.DEPARTMENT_RAW (store_id, dept_id, date, weekly_sales, is_holiday)
VALUES (10, 5, '2026-09-13', 1000, FALSE);  -- keeps the (10,5) pair present for the join


-- SCD2 Test


SELECT * FROM WALMART_DEV.SILVER.SALES_FACT WHERE store_id = 10 AND dept_id = 5 AND date_id = 20111216;


INSERT INTO WALMART_DEV.RAW.FACT_RAW (store_id, date, fuel_price, temperature, unemployment, cpi)
VALUES (10, '2011-12-16', 3.50, 72.0, 5.1, 210.5);

INSERT INTO WALMART_DEV.RAW.DEPARTMENT_RAW (store_id, dept_id, date, weekly_sales, is_holiday)
VALUES (10, 5, '2011-12-16', 99999, FALSE);  -- changed weekly_sales


SELECT store_id, dept_id, date_id, weekly_sales, dbt_valid_from, dbt_valid_to
FROM WALMART_DEV.SILVER.SNAP_SALES
WHERE store_id = 10 AND dept_id = 5 AND date_id = 20111216
ORDER BY dbt_valid_from;


SELECT store_id, dept_id, date_id, store_weekly_sales, vrsn_start_date, vrsn_end_date
FROM WALMART_DEV.SILVER.SALES_FACT
WHERE store_id = 10 AND dept_id = 5 AND date_id = 20111216
ORDER BY vrsn_start_date;



SELECT * FROM WALMART_DEV.GOLD.SALES_REPORTS;