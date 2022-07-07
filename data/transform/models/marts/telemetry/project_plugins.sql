WITH plugins AS (
    SELECT DISTINCT
        plugin_executions.event_ts::DATE AS date_day,
        plugin_executions.project_id,
        CASE
            WHEN
                plugin_executions.plugin_category NOT IN (
                    'singer', 'dbt', 'great_expectations', 'superset', 'airflow'
                ) THEN 'other'
            ELSE plugin_executions.plugin_category
        END AS plugin_category
    FROM {{ ref('plugin_executions') }}
    LEFT JOIN {{ ref('execution_dim') }}
        ON plugin_executions.execution_id = execution_dim.execution_id
    LEFT JOIN {{ ref('project_dim') }}
        ON plugin_executions.project_id = project_dim.project_id
    WHERE
        execution_dim.is_exec_event
        AND DATEDIFF(
            'day',
            project_dim.first_event_at::TIMESTAMP,
            plugin_executions.event_ts::DATE
        ) >= 7

),

plugins_per_project AS (
    SELECT
        date_dim.date_day,
        (
            SELECT COUNT(DISTINCT project_id)
            FROM plugins
            WHERE plugins.date_day BETWEEN DATEADD(
                    DAY, -14, date_dim.date_day
                ) AND date_dim.date_day
        ) AS projects,
        (
            SELECT COUNT(DISTINCT project_id, plugin_category)
            FROM plugins
            WHERE plugins.date_day BETWEEN DATEADD(
                    DAY, -14, date_dim.date_day
                ) AND date_dim.date_day
        ) AS categories
    FROM {{ ref('date_dim') }}
    WHERE date_dim.date_day <= CURRENT_TIMESTAMP()
    HAVING projects > 0
)

SELECT
    date_day,
    projects,
    categories,
    categories / projects AS avg_plugin_per_project
FROM plugins_per_project
