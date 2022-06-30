WITH retention AS (
    SELECT
        project_id,
        MIN(event_created_at) AS first_event_date,
        MAX(event_created_at) AS last_event_date,
        COALESCE(SUM(
            event_count
        ) = 1 AND MAX(command_category) = 'meltano init',
        FALSE) AS tracking_disabled
    FROM {{ ref('structured_executions') }}
    GROUP BY 1
),

unstruct_prep AS (

    SELECT
        execution_id,
        MAX(
            COALESCE(cli_command IN (
                'meltano invoke',
                'meltano elt',
                'meltano run',
                'meltano test',
                'meltano ui',
                'invoke',
                'elt',
                'run',
                'test',
                'ui'
            )
            OR (
                struct_command_category = 'meltano schedule'
                AND cli_command LIKE '% run %'
            ),
            FALSE)
        ) AS is_exec_event,
        MAX(
            COALESCE(cli_command IN (
                'meltano invoke',
                'meltano elt',
                'meltano run',
                'invoke',
                'elt',
                'run'
            )
            OR (
                struct_command_category = 'meltano schedule'
                AND cli_command LIKE '% run %'
            ),
            FALSE
            )
        ) AS is_pipeline_exec_event,
        MAX(
            COALESCE(cli_command IN (
                'meltano transforms',
                'meltano dashboards',
                'meltano models',
                'transforms',
                'dashboards',
                'models'
            ), FALSE)) AS is_legacy_event,
        MAX(COALESCE(plugin_category = 'dbt', FALSE)) AS is_plugin_dbt,
        MAX(COALESCE(plugin_category = 'singer', FALSE)) AS is_plugin_singer,
        MAX(COALESCE(plugin_category = 'airflow', FALSE)) AS is_plugin_airflow,
        MAX(COALESCE(plugin_category = 'dagster', FALSE)) AS is_plugin_dagster,
        MAX(
            COALESCE(plugin_category = 'lightdash', FALSE)
        ) AS is_plugin_lightdash,
        MAX(
            COALESCE(plugin_category = 'superset', FALSE)
        ) AS is_plugin_superset,
        MAX(
            COALESCE(plugin_category = 'sqlfluff', FALSE)
        ) AS is_plugin_sqlfluff,
        MAX(
            COALESCE(plugin_category = 'great_expectations', FALSE)
        ) AS is_plugin_great_ex,
        -- OS Features
        MAX(COALESCE(env_id IS NOT NULL, FALSE)) AS is_os_feature_environments,
        MAX(COALESCE(plugin_type = 'mappers', FALSE)) AS is_os_feature_mappers,
        MAX(
            COALESCE(cli_command IN ('meltano test', 'test'), FALSE)
        ) AS is_os_feature_test,
        MAX(
            COALESCE(cli_command IN ('meltano run', 'run'), FALSE)
        ) AS is_os_feature_run,
        MAX(
            COALESCE(
                plugin_category NOT IN (
                    'dbt',
                    'singer',
                    'airflow',
                    'dagster',
                    'lightdash',
                    'superset',
                    'sqlfluff',
                    'great_expectations'
                ),
                FALSE
            )
        ) AS is_plugin_other
    FROM {{ ref('fact_plugin_usage') }}
    GROUP BY 1

)

SELECT
    structured_executions.execution_id,
    structured_executions.event_created_date AS event_date,
    structured_executions.event_created_at,
    structured_executions.command_category,
    structured_executions.command,
    structured_executions.project_id,
    retention.tracking_disabled AS is_tracking_disabled,
    structured_executions.event_count,
    event_commands_parsed.is_exec_event,
    event_commands_parsed.is_pipeline_exec_event,
    event_commands_parsed.is_legacy_event,
    -- Plugins
    event_commands_parsed.is_plugin_dbt,
    event_commands_parsed.is_plugin_singer,
    event_commands_parsed.is_plugin_airflow,
    event_commands_parsed.is_plugin_dagster,
    event_commands_parsed.is_plugin_lightdash,
    event_commands_parsed.is_plugin_superset,
    event_commands_parsed.is_plugin_sqlfluff,
    event_commands_parsed.is_plugin_great_ex,
    -- OS Features
    event_commands_parsed.is_os_feature_environments,
    event_commands_parsed.is_os_feature_mappers,
    event_commands_parsed.is_os_feature_test,
    event_commands_parsed.is_os_feature_run,
    COALESCE(NOT(event_commands_parsed.is_plugin_dbt
        OR event_commands_parsed.is_plugin_singer
        OR event_commands_parsed.is_plugin_airflow
        OR event_commands_parsed.is_plugin_dagster
        OR event_commands_parsed.is_plugin_lightdash
        OR event_commands_parsed.is_plugin_superset
        OR event_commands_parsed.is_plugin_sqlfluff
        OR event_commands_parsed.is_plugin_great_ex
    ), FALSE) AS is_plugin_other,
    COALESCE(
        retention.first_event_date = structured_executions.event_created_at,
        FALSE) AS is_acquired_date,
    COALESCE(retention.last_event_date = structured_executions.event_created_at,
        FALSE) AS is_churned_date,
    COALESCE(
        structured_executions.event_created_at >= DATEADD(
            MONTH, 1, DATE_TRUNC(
                'MONTH', retention.first_event_date
            )
        )
        AND structured_executions.event_created_at < DATE_TRUNC(
            'MONTH', retention.last_event_date
        ), FALSE
    ) AS is_retained_date
FROM {{ ref('structured_executions') }}
LEFT JOIN {{ ref('event_commands_parsed') }}
    ON structured_executions.command = event_commands_parsed.command
LEFT JOIN retention ON structured_executions.project_id = retention.project_id

UNION

SELECT
    unstructured_executions.execution_id,
    unstructured_executions.event_created_date AS event_date,
    unstructured_executions.event_created_at,
    unstructured_executions.struct_command_category,
    unstructured_executions.cli_command AS command,
    unstructured_executions.project_id,
    NULL AS is_tracking_disabled,
    1 AS event_count,
    unstruct_prep.is_exec_event,
    unstruct_prep.is_pipeline_exec_event,
    unstruct_prep.is_legacy_event,
    -- Plugins
    unstruct_prep.is_plugin_dbt,
    unstruct_prep.is_plugin_singer,
    unstruct_prep.is_plugin_airflow,
    unstruct_prep.is_plugin_dagster,
    unstruct_prep.is_plugin_lightdash,
    unstruct_prep.is_plugin_superset,
    unstruct_prep.is_plugin_sqlfluff,
    unstruct_prep.is_plugin_great_ex,
    -- OS Features
    unstruct_prep.is_os_feature_environments,
    unstruct_prep.is_os_feature_mappers,
    unstruct_prep.is_os_feature_test,
    unstruct_prep.is_os_feature_run,
    unstruct_prep.is_plugin_other,
    NULL AS is_acquired_date,
    NULL AS is_churned_date,
    NULL AS is_retained_date
FROM {{ ref('unstructured_executions') }}
LEFT JOIN unstruct_prep
    ON unstructured_executions.execution_id = unstruct_prep.execution_id
