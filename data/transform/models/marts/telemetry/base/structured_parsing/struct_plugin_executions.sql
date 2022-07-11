{{
    config(materialized='table')
}}

SELECT
    {{ dbt_utils.surrogate_key(
        [
            'struct_plugins.plugin_name',
            'structured_executions.execution_id'
        ]
    ) }} AS struct_plugin_exec_pk,
    structured_executions.execution_id,
    structured_executions.event_created_at AS event_ts,
    structured_executions.event_count AS event_count,
    structured_executions.event_source,
    SPLIT_PART(cmd_parsed_all.command_category, ' ', 2) AS command,
    cmd_parsed_all.command AS full_struct_command,
    cmd_parsed_all.command_category,
    -- plugins
    struct_plugins.plugin_name AS plugin_name,
    struct_plugins.plugin_category,
    structured_executions.project_id,
    cmd_parsed_all.environment AS env_id
FROM {{ ref('structured_executions') }}
LEFT JOIN
    {{ ref('cmd_parsed_all') }} ON
        structured_executions.command = cmd_parsed_all.command
LEFT JOIN
    {{ ref('struct_plugins') }} ON
        structured_executions.command = struct_plugins.command
WHERE cmd_parsed_all.command_type = 'plugin'
    AND struct_plugins.plugin_name IS NOT NULL
