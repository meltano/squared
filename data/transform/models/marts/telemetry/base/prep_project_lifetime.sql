{{
    config(
        materialized='table',
        description="A prep table to calculate relative project dates, ages, etc."
    )
}}

WITH cte_max_date_thresholds AS (
    # Generates a single row containing the max date (aka "today" based on upsteam EL)
    SELECT
        MAX(cli_executions_base.event_created_at)::DATE AS latest_data_date,
        MAX(cli_executions_base.event_created_at)       AS latest_data_timestamp,
    FROM {{ ref('cli_executions_base') }} AS cli_executions_base
),

cte_vital_dates AS (
    SELECT
        cli_executions_base.project_id,
        min(cli_executions_base.first_event_at::TIMESTAMP) AS first_event_at,
        max(cli_executions_base.first_event_at::TIMESTAMP) AS last_event_at,
    FROM {{ ref('cli_executions_base') }} AS cli_executions_base
    WHERE
        cli_executions_base.is_exec_event
),

cte_project_datemath AS
(
    SELECT
        cte_project_dates.project_id,
        cte_project_dates.first_event_at,
        cte_project_dates.last_event_at,
        DATEDIFF(
            'day',
            cte_project_dates.first_event_at::TIMESTAMP,
            cte_project_dates.event_created_at::TIMESTAMP
        ) as latest_project_age_in_days
        DATEDIFF(
            'hour',
            cte_project_dates.first_event_at::TIMESTAMP,
            cte_project_dates.event_created_at::TIMESTAMP
        ) as latest_project_age_in_hours
        DATEDIFF(
            'day',
            cte_project_dates.first_event_at::TIMESTAMP,
            cte_max_date_thresholds.latest_data_timestamp
        ) as days_since_first_event -- The 'age' if the project were still active (raw days elapsed).
        DATEDIFF(
            'day',
            cte_project_dates.last_event_at::TIMESTAMP,
            cte_max_date_thresholds.latest_data_timestamp
        ) as days_since_last_event -- The number of days elapsed since we've seen this project.
    FROM cte_project_dates
    CROSS JOIN cte_max_date_thresholds
)

SELECT
    cte_project_datemath.project_id
    cte_project_datemath.first_event_at
    cte_project_datemath.last_event_at
    cte_project_datemath.latest_project_age_in_days
    cte_project_datemath.latest_project_age_in_hours
    cte_project_datemath.days_since_first_event
    cte_project_datemath.days_since_last_event
    CASE 
        WHEN cte_project_datemath.latest_project_age_in_hours < 3
        THEN TRUE
        ELSE FALSE
    END AS is_ephemeral_project_id
FROM cte_project_datemath
