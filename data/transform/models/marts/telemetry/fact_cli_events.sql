WITH retention AS (
    SELECT
        project_id,
        MIN(event_date) AS first_event_date,
        MAX(event_date) AS last_event_date,
        COALESCE(SUM(
            event_count
        ) = 1 AND MAX(command_category) = 'meltano init',
        FALSE) AS tracking_disabled
    FROM {{ ref('stg_ga__cli_events') }}
    GROUP BY project_id
)

SELECT
    stg_ga__cli_events.event_date,
    stg_ga__cli_events.command_category,
    stg_ga__cli_events.command,
    stg_ga__cli_events.project_id,
    retention.tracking_disabled AS is_tracking_disabled,
    stg_ga__cli_events.event_count,
    ga_commands_parsed.is_exec_event,
    ga_commands_parsed.is_pipeline_exec_event,
    ga_commands_parsed.is_legacy_event,
    -- Plugins
    ga_commands_parsed.is_plugin_dbt,
    ga_commands_parsed.is_plugin_singer,
    ga_commands_parsed.is_plugin_airflow,
    ga_commands_parsed.is_plugin_dagster,
    ga_commands_parsed.is_plugin_lightdash,
    ga_commands_parsed.is_plugin_superset,
    ga_commands_parsed.is_plugin_sqlfluff,
    ga_commands_parsed.is_plugin_great_ex,
    -- OS Features
    ga_commands_parsed.is_os_feature_environments,
    ga_commands_parsed.is_os_feature_stream_map,
    ga_commands_parsed.is_os_feature_test,
    ga_commands_parsed.is_os_feature_run,
    COALESCE(NOT(ga_commands_parsed.is_plugin_dbt
        OR ga_commands_parsed.is_plugin_singer
        OR ga_commands_parsed.is_plugin_airflow
        OR ga_commands_parsed.is_plugin_dagster
        OR ga_commands_parsed.is_plugin_lightdash
        OR ga_commands_parsed.is_plugin_superset
        OR ga_commands_parsed.is_plugin_sqlfluff
        OR ga_commands_parsed.is_plugin_great_ex
    ), FALSE) AS is_plugin_other,
    COALESCE(retention.first_event_date = stg_ga__cli_events.event_date,
        FALSE) AS is_acquired_date,
    COALESCE(retention.last_event_date = stg_ga__cli_events.event_date,
        FALSE) AS is_churned_date,
    COALESCE(stg_ga__cli_events.event_date >= DATEADD(MONTH, 1, DATE_TRUNC(
        'MONTH', retention.first_event_date
            )) AND stg_ga__cli_events.event_date < DATE_TRUNC(
            'MONTH', retention.last_event_date
    ),
    FALSE) AS is_retained_date
FROM {{ ref('stg_ga__cli_events') }}
LEFT JOIN {{ ref('ga_commands_parsed') }}
    ON stg_ga__cli_events.command = ga_commands_parsed.command
LEFT JOIN retention ON stg_ga__cli_events.project_id = retention.project_id
