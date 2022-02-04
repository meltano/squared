{{
    config(
        materialized = "table"
    )
}}
-- This is a hack since I cant get dbt_utils and dbt_date working with Athena
SELECT
	CAST(d AS date) AS date_day
FROM UNNEST(SEQUENCE(DATE '2020-01-01', CURRENT_DATE, INTERVAL '1' DAY)) f(d)

