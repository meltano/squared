SELECT
    stg_ga__cli_events.event_date,
    stg_ga__cli_events.command_category,
    stg_ga__cli_events.command,
    stg_ga__cli_events.project_id,
    stg_ga__cli_events.event_count,
    ga_commands_parsed.is_exec_event,
    ga_commands_parsed.is_legacy_event,
    -- Plugins
    ga_commands_parsed.is_plugin_dbt,
    ga_commands_parsed.is_plugin_singer,
    ga_commands_parsed.is_plugin_airflow,
    ga_commands_parsed.is_plugin_dagster,
    ga_commands_parsed.is_plugin_lightdash,
    ga_commands_parsed.is_plugin_superset,
    ga_commands_parsed.is_plugin_sqlfluff,
    -- OS Features
    ga_commands_parsed.is_os_feature_environments,
    ga_commands_parsed.is_os_feature_test,
    ga_commands_parsed.is_os_feature_run
FROM {{ ref('stg_ga__cli_events') }}
LEFT JOIN {{ ref('ga_commands_parsed') }}
    ON stg_ga__cli_events.command = ga_commands_parsed.command
