{{
    config(materialized='table')
}}

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
    FROM {{ ref('plugin_executions') }}
    GROUP BY 1

),

combined AS (

    SELECT
        structured_executions.execution_id,
        structured_executions.event_created_date AS event_date,
        structured_executions.event_created_at,
        structured_executions.command_category,
        structured_executions.command,
        SPLIT_PART(
            structured_executions.command_category,
            ' ',
            2
        ) AS cli_command,
        NULL AS cli_sub_command,
        structured_executions.project_id,
        NULL AS project_uuid_source,
        retention.tracking_disabled AS is_tracking_disabled,
        structured_executions.event_count,
        structured_executions.ip_address_hash,
        NULL AS meltano_version,
        NULL AS python_version,
        NULL AS is_ci_environment,
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
        COALESCE(
            retention.last_event_date = structured_executions.event_created_at,
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
    LEFT JOIN retention
        ON structured_executions.project_id = retention.project_id

    UNION

    SELECT
        unstructured_executions.execution_id,
        unstructured_executions.event_created_date AS event_date,
        unstructured_executions.event_created_at,
        unstructured_executions.struct_command_category,
        unstructured_executions.struct_command AS command,
        unstructured_executions.cli_command AS cli_command,
        unstructured_executions.cli_sub_command AS cli_sub_command,
        unstructured_executions.project_id,
        unstructured_executions.project_uuid_source,
        FALSE AS is_tracking_disabled,
        1 AS event_count,
        MD5(unstructured_executions.user_ipaddress) AS ip_address_hash,
        unstructured_executions.meltano_version,
        unstructured_executions.python_version,
        unstructured_executions.is_ci_environment,
        COALESCE(unstruct_prep.is_exec_event, FALSE) AS is_exec_event,
        COALESCE(
            unstruct_prep.is_pipeline_exec_event,
            FALSE
        ) AS is_pipeline_exec_event,
        COALESCE(unstruct_prep.is_legacy_event, FALSE) AS is_legacy_event,
        -- Plugins
        COALESCE(unstruct_prep.is_plugin_dbt, FALSE) AS is_plugin_dbt,
        COALESCE(unstruct_prep.is_plugin_singer, FALSE) AS is_plugin_singer,
        COALESCE(unstruct_prep.is_plugin_airflow, FALSE) AS is_plugin_airflow,
        COALESCE(unstruct_prep.is_plugin_dagster, FALSE) AS is_plugin_dagster,
        COALESCE(
            unstruct_prep.is_plugin_lightdash,
            FALSE
        ) AS is_plugin_lightdash,
        COALESCE(unstruct_prep.is_plugin_superset, FALSE) AS is_plugin_superset,
        COALESCE(unstruct_prep.is_plugin_sqlfluff, FALSE) AS is_plugin_sqlfluff,
        COALESCE(unstruct_prep.is_plugin_great_ex, FALSE) AS is_plugin_great_ex,
        -- OS Features
        COALESCE(
            unstruct_prep.is_os_feature_environments,
            FALSE
        ) AS is_os_feature_environments,
        COALESCE(
            unstruct_prep.is_os_feature_mappers,
            FALSE
        ) AS is_os_feature_mappers,
        COALESCE(unstruct_prep.is_os_feature_test, FALSE) AS is_os_feature_test,
        COALESCE(unstruct_prep.is_os_feature_run, FALSE) AS is_os_feature_run,
        COALESCE(unstruct_prep.is_plugin_other, FALSE) AS is_plugin_other,
        NULL AS is_acquired_date,
        NULL AS is_churned_date,
        NULL AS is_retained_date
    FROM {{ ref('unstructured_executions') }}
    LEFT JOIN unstruct_prep
        ON unstructured_executions.execution_id = unstruct_prep.execution_id

)

SELECT
    combined.execution_id,
    combined.event_date,
    combined.event_created_at,
    combined.command_category,
    combined.command,
    combined.cli_command,
    combined.cli_sub_command,
    combined.project_id,
    combined.project_uuid_source,
    combined.is_tracking_disabled,
    combined.event_count,
    combined.ip_address_hash,
    combined.meltano_version,
    combined.python_version,
    combined.is_ci_environment,
    combined.is_exec_event,
    combined.is_pipeline_exec_event,
    combined.is_legacy_event,
    combined.is_plugin_dbt,
    combined.is_plugin_singer,
    combined.is_plugin_airflow,
    combined.is_plugin_dagster,
    combined.is_plugin_lightdash,
    combined.is_plugin_superset,
    combined.is_plugin_sqlfluff,
    combined.is_plugin_great_ex,
    combined.is_os_feature_environments,
    combined.is_os_feature_mappers,
    combined.is_os_feature_test,
    combined.is_os_feature_run,
    combined.is_plugin_other,
    combined.is_acquired_date,
    combined.is_churned_date,
    combined.is_retained_date
FROM combined
