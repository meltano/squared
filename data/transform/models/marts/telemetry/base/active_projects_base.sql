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
LEFT JOIN {{ ref('pipeline_executions') }}
    ON cli_executions_base.execution_id = pipeline_executions.execution_id
WHERE
    pipeline_executions.pipeline_pk IS NOT NULL
    AND DATEDIFF(
        'day',
        project_base.first_event_at::TIMESTAMP,
        cli_executions_base.event_created_at::DATE
    ) >= 7
    AND project_base.project_id_source != 'random'
