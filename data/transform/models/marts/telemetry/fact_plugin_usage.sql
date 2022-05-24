SELECT
    {{ dbt_utils.surrogate_key(
        [
            'plugins.plugin_name',
            'structured_events.event_id'
        ]
    ) }} AS plugin_usage_pk,
    structured_events.event_id,
    NULL AS trace_id,
    structured_events.event_created_at AS event_ts,
    structured_events.event_count,
    structured_events.event_source,
    structured_events.event_type, -- structured
    structured_events.command,
    cmd_parsed_all.command_category,
    cmd_parsed_all.args,
    -- plugin dim
    plugins.plugin_name AS plugin_name,
    NULL AS plugin_variant,
    NULL AS plugin_version,
    plugins.plugin_category,
    -- project dim
    structured_events.project_id,
    projects.first_event_at AS project_created_at,
    projects.is_active AS project_is_active,
    -- environment dim
    cmd_parsed_all.environment AS env_id,
    environments.env_name,
    environments.is_ephemeral AS env_is_ephemeral,
    environments.is_cicd AS env_is_cicd,
    environments.is_cloud AS env_is_cloud,
    -- execution dim
    0 AS exit_code,
    NULL AS execution_time_s
FROM {{ ref('structured_events') }}
LEFT JOIN
    {{ ref('cmd_parsed_all') }} ON
        structured_events.command = cmd_parsed_all.command
LEFT JOIN
    {{ ref('environments') }} ON
        structured_events.event_id = environments.event_id
LEFT JOIN
    {{ ref('projects') }} ON structured_events.project_id = projects.project_id
LEFT JOIN {{ ref('plugins') }} ON structured_events.command = plugins.command
WHERE cmd_parsed_all.command_type = 'plugin'
    AND plugins.plugin_name IS NOT NULL
