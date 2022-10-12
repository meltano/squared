{{
    config(materialized='table')
}}

SELECT DISTINCT
    cli_executions_base.event_created_at::DATE AS date_day,
    project_base.project_id,
    CASE
        WHEN
            plugin_executions.plugin_category NOT IN (
                'singer', 'dbt', 'great_expectations', 'superset', 'airflow'
            ) THEN 'other'
        ELSE plugin_executions.plugin_category
    END AS plugin_category
FROM {{ ref('plugin_executions') }}
LEFT JOIN {{ ref('cli_executions_base') }}
    ON plugin_executions.execution_id = cli_executions_base.execution_id
LEFT JOIN {{ ref('project_base') }}
    ON cli_executions_base.project_id = project_base.project_id
WHERE
    cli_executions_base.is_exec_event
    AND DATEDIFF(
        'day',
        project_base.first_event_at::TIMESTAMP,
        cli_executions_base.event_created_at::DATE
    ) >= 1
    AND project_base.project_id_source != 'random'
