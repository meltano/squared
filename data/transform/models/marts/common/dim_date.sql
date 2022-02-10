{{
    config(
        materialized = "table"
    )
}}
-- This is a hack since I cant get dbt_utils and dbt_date working with Athena
SELECT CAST(d AS DATE) AS date_day
FROM UNNEST(
    SEQUENCE(
        DATE '2017-01-01', CURRENT_DATE, INTERVAL '1' DAY
    )
) AS f(d) -- noqa: L025
