WITH projects_by_day AS (
    SELECT
        event_date,
        COUNT(DISTINCT project_id) AS daily_pid_count
    FROM {{ ref('stg_ga__cli_events') }} GROUP BY 1
)

SELECT
    DATE_TRUNC('day', event_date) AS event_date,
    SUM(
        daily_pid_count
    ) OVER (
        ORDER BY
            DATE_TRUNC('day', event_date)
        ROWS BETWEEN 28 PRECEDING AND CURRENT ROW
    ) AS project_cnt_28d
FROM projects_by_day ORDER BY 1 DESC
