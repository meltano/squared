{{
    config(materialized='table')
}}

WITH base AS (
    SELECT DISTINCT
        cli_executions_base.event_created_at::DATE AS date_day,
        project_dim.project_id,
        CASE
            WHEN
                plugin_executions.plugin_category NOT IN (
                    'singer', 'dbt', 'great_expectations', 'superset', 'airflow'
                ) THEN 'other'
            ELSE plugin_executions.plugin_category
        END AS plugin_category,
        DATEDIFF(
            'day',
            project_dim.first_event_at::TIMESTAMP,
            cli_executions_base.event_created_at::DATE
        ) AS days_from_first_event
    FROM PREP.workspace.plugin_executions
    LEFT JOIN PREP.workspace.cli_executions_base
        ON plugin_executions.execution_id = cli_executions_base.execution_id
    LEFT JOIN PREP.workspace.project_dim
        ON cli_executions_base.project_id = project_dim.project_id
    LEFT JOIN PREP.workspace.unstructured_executions
        ON plugin_executions.execution_id = unstructured_executions.execution_id
    WHERE
        cli_executions_base.is_exec_event
        -- TODO: move project_uuid_source upstream to cli_executions_base
        AND COALESCE(
            unstructured_executions.project_uuid_source,
            ''
        ) != 'random'
)
SELECT
    date_dim.date_day AS date_day_28d,
    base.*
FROM PREP.workspace.date_dim
INNER JOIN base
ON base.date_day BETWEEN DATEADD(
                    DAY, -28, date_dim.date_day
                ) AND date_dim.date_day
WHERE date_dim.date_day <= CURRENT_TIMESTAMP()
