WITH date_spine AS (

  {{ dbt_utils.date_spine(
      start_date="to_date('12/01/2015', 'mm/dd/yyyy')",
      datepart="day",
      end_date="dateadd(year, 40, current_date)"
     )
  }}

),

calculated AS (

    SELECT
        date_day,

        DAYNAME(
            date_day
        ) AS day_name,

        DATE_PART(
            'month', date_day
        ) AS month_actual,

        DATE_PART(
            'year', date_day
        ) AS year_actual,

        DATE_PART(
            QUARTER, date_day
        ) AS quarter_actual,

        DATE_PART(
            DAYOFWEEK, date_day
        ) + 1 AS day_of_week,

        CASE WHEN day_name = 'Sun' THEN date_day
            ELSE DATEADD(
                'day', -1, DATE_TRUNC('week', date_day)
            ) END AS first_day_of_week,

        CASE WHEN day_name = 'Sun' THEN WEEK(date_day) + 1
            --remove this column
            ELSE WEEK(date_day) END AS week_of_year_temp,

        CASE
            WHEN
                day_name = 'Sun' AND LEAD(
                    week_of_year_temp
                ) OVER (ORDER BY date_day) = '1'
                THEN '1'
            ELSE week_of_year_temp END AS week_of_year,

        DATE_PART(
            'day', date_day
        ) AS day_of_month,

        ROW_NUMBER() OVER (
            PARTITION BY year_actual, quarter_actual ORDER BY date_day
        ) AS day_of_quarter,

        ROW_NUMBER() OVER (
            PARTITION BY year_actual ORDER BY date_day
        ) AS day_of_year,

        CASE WHEN month_actual < 2
            THEN year_actual
            ELSE (year_actual + 1) END AS fiscal_year,

        CASE WHEN month_actual < 2 THEN '4'
            WHEN month_actual < 5 THEN '1'
            WHEN month_actual < 8 THEN '2'
            WHEN month_actual < 11 THEN '3'
            ELSE '4' END AS fiscal_quarter,

        ROW_NUMBER() OVER (
            PARTITION BY fiscal_year, fiscal_quarter ORDER BY date_day
        ) AS day_of_fiscal_quarter,

        ROW_NUMBER() OVER (
            PARTITION BY fiscal_year ORDER BY date_day
        ) AS day_of_fiscal_year,

        TO_CHAR(
            date_day, 'MMMM'
        ) AS month_name,

        TRUNC(
            date_day, 'Month'
        ) AS first_day_of_month,

        LAST_VALUE(
            date_day
        ) OVER (
            PARTITION BY year_actual, month_actual ORDER BY date_day
        ) AS last_day_of_month,

        FIRST_VALUE(
            date_day
        ) OVER (
            PARTITION BY year_actual ORDER BY date_day
        ) AS first_day_of_year,

        LAST_VALUE(
            date_day
        ) OVER (PARTITION BY year_actual ORDER BY date_day) AS last_day_of_year,

        FIRST_VALUE(
            date_day
        ) OVER (
            PARTITION BY year_actual, quarter_actual ORDER BY date_day
        ) AS first_day_of_quarter,

        LAST_VALUE(
            date_day
        ) OVER (
            PARTITION BY year_actual, quarter_actual ORDER BY date_day
        ) AS last_day_of_quarter,

        FIRST_VALUE(
            date_day
        ) OVER (
            PARTITION BY fiscal_year, fiscal_quarter ORDER BY date_day
        ) AS first_day_of_fiscal_quarter,

        LAST_VALUE(
            date_day
        ) OVER (
            PARTITION BY fiscal_year, fiscal_quarter ORDER BY date_day
        ) AS last_day_of_fiscal_quarter,

        FIRST_VALUE(
            date_day
        ) OVER (
            PARTITION BY fiscal_year ORDER BY date_day
        ) AS first_day_of_fiscal_year,

        LAST_VALUE(
            date_day
        ) OVER (
            PARTITION BY fiscal_year ORDER BY date_day
        ) AS last_day_of_fiscal_year,

        DATEDIFF(
            'week', first_day_of_fiscal_year, date_day
        ) + 1 AS week_of_fiscal_year,

        CASE WHEN EXTRACT('month', date_day) = 1 THEN 12
            ELSE EXTRACT('month', date_day) - 1 END AS month_of_fiscal_year,

        LAST_VALUE(
            date_day
        ) OVER (
            PARTITION BY first_day_of_week ORDER BY date_day
        ) AS last_day_of_week,

        (
            year_actual || '-Q' || EXTRACT(QUARTER FROM date_day)
        ) AS quarter_name,

        (fiscal_year || '-' || DECODE(fiscal_quarter,
            1, 'Q1',
            2, 'Q2',
            3, 'Q3',
            4, 'Q4'
        )) AS fiscal_quarter_name,

        (
            'FY' || SUBSTR(fiscal_quarter_name, 3, 7)
        ) AS fiscal_quarter_name_fy,

        fiscal_year || '-' || MONTHNAME(
            date_day
        ) AS fiscal_month_name,

        (
            'FY' || SUBSTR(fiscal_month_name, 3, 8)
        ) AS fiscal_month_name_fy,

        COUNT(date_day) OVER (
            PARTITION BY first_day_of_month
        ) AS days_in_month_count

    FROM date_spine

)

SELECT *
FROM calculated
