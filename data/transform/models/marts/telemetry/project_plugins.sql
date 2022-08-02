WITH plugins AS (
    SELECT DISTINCT
        cli_executions_base.event_created_at::DATE AS date_day,
        project_dim.project_id,
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
    LEFT JOIN {{ ref('project_dim') }}
        ON cli_executions_base.project_id = project_dim.project_id
    LEFT JOIN {{ ref('unstructured_executions') }}
        ON plugin_executions.execution_id = unstructured_executions.execution_id
    WHERE
        cli_executions_base.is_exec_event
        AND DATEDIFF(
            'day',
            project_dim.first_event_at::TIMESTAMP,
            cli_executions_base.event_created_at::DATE
        ) >= 7
        -- TODO: move project_uuid_source upstream to cli_executions_base
        AND COALESCE(
            unstructured_executions.project_uuid_source,
            ''
        ) != 'random'

),

plugins_per_project AS (
    SELECT
        date_dim.date_day,
        (
            SELECT COUNT(
                DISTINCT plugins.project_id
            )
            FROM plugins
            WHERE plugins.date_day BETWEEN DATEADD(
                    DAY, -28, date_dim.date_day
                ) AND date_dim.date_day
        ) AS projects_28d,
        (
            SELECT COUNT(
                DISTINCT
                plugins.project_id,
                plugins.plugin_category
            )
            FROM plugins
            WHERE plugins.date_day BETWEEN DATEADD(
                    DAY, -28, date_dim.date_day
                ) AND date_dim.date_day
        ) AS plugin_categories_28d,
        (
            SELECT COUNT(
                DISTINCT plugins.project_id
            )
            FROM plugins
            WHERE plugins.date_day BETWEEN DATEADD(
                    DAY, -14, date_dim.date_day
                ) AND date_dim.date_day
        ) AS projects_14d,
        (
            SELECT COUNT(
                DISTINCT
                plugins.project_id,
                plugins.plugin_category
            )
            FROM plugins
            WHERE plugins.date_day BETWEEN DATEADD(
                    DAY, -14, date_dim.date_day
                ) AND date_dim.date_day
        ) AS plugin_categories_14d,
        (
            SELECT COUNT(
                DISTINCT plugins.project_id
            )
            FROM plugins
            WHERE plugins.date_day BETWEEN DATEADD(
                    DAY, -7, date_dim.date_day
                ) AND date_dim.date_day
        ) AS projects_7d,
        (
            SELECT COUNT(
                DISTINCT
                plugins.project_id,
                plugins.plugin_category
            )
            FROM plugins
            WHERE plugins.date_day BETWEEN DATEADD(
                    DAY, -7, date_dim.date_day
                ) AND date_dim.date_day
        ) AS plugin_categories_7d
    FROM {{ ref('date_dim') }}
    WHERE date_dim.date_day <= CURRENT_TIMESTAMP()
    HAVING projects_28d > 0
)

SELECT
    date_day,
    projects_28d,
    plugin_categories_28d,
    projects_14d,
    plugin_categories_14d,
    projects_7d,
    plugin_categories_7d,
    plugin_categories_28d / NULLIF(projects_28d, 0) AS app_28d,
    plugin_categories_14d / NULLIF(projects_14d, 0) AS app_14d,
    plugin_categories_7d / NULLIF( projects_7d, 0) AS app_7d
FROM plugins_per_project
