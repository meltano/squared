WITH base AS (
    SELECT
        unstructured_executions.*,
        plugin.value AS plugin_details
    FROM {{ ref('unstructured_executions') }},
        LATERAL FLATTEN(input => plugins) AS plugin_list, -- noqa: L025, L031
        LATERAL FLATTEN(
            input => plugin_list.value::VARIANT
        ) AS plugin -- noqa: L031
)

SELECT DISTINCT
    {{ dbt_utils.surrogate_key(
        [
            'unstruct_plugins.plugin_surrogate_key',
            'base.execution_id'
        ]
    ) }} AS plugin_usage_pk,
    base.execution_id,
    base.started_ts AS event_ts,
    1 AS event_count,
    base.event_source,
    base.event_type,
    COALESCE(
        base.cli_command, SPLIT_PART(base.struct_command_category, ' ', 2)
    ) AS command,
    base.struct_command AS full_command,
    base.struct_command_category,
    -- plugins
    unstruct_plugins.plugin_name AS plugin_name,
    unstruct_plugins.parent_name AS parent_name,
    unstruct_plugins.executable AS executable,
    unstruct_plugins.namespace AS namespace,
    unstruct_plugins.pip_url AS pip_url,
    unstruct_plugins.variant_name AS plugin_variant,
    unstruct_plugins.command AS plugin_command,
    unstruct_plugins.plugin_type,
    unstruct_plugins.plugin_category,
    -- projects
    base.project_id,
    projects.first_event_at AS project_created_at,
    projects.is_active AS project_is_active,
    -- environments
    base.environment_name_hash AS env_id,
    hash_lookup.unhashed_value AS env_name,
    -- executions
    base.exit_code AS exit_code,
    base.process_duration_ms AS execution_time_ms,
    -- random
    base.user_ipaddress,
    base.meltano_version,
    base.num_cpu_cores_available,
    base.windows_edition,
    base.machine,
    base.system_release,
    base.freedesktop_id,
    base.freedesktop_id_like,
    base.is_dev_build,
    base.process_hierarchy,
    base.python_version,
    base.client_uuid,
    base.is_ci_environment,
    base.num_cpu_cores,
    base.python_implementation,
    base.system_name,
    base.system_version,
    base.exception_type,
    base.exception_cause,
    base.event_states,
    base.event_block_types
FROM base
LEFT JOIN {{ ref('unstruct_plugins') }}
    ON unstruct_plugins.plugin_surrogate_key = {{ dbt_utils.surrogate_key(
        ['base.plugin_details']
    ) }}
LEFT JOIN {{ ref('hash_lookup') }}
    ON base.environment_name_hash = hash_lookup.hash_value
LEFT JOIN
    {{ ref('projects') }} ON base.project_id = projects.project_id

UNION ALL

SELECT
    {{ dbt_utils.surrogate_key(
        [
            'plugins_cmd_map.plugin_name',
            'structured_executions.event_id'
        ]
    ) }} AS plugin_usage_pk,
    structured_executions.event_id AS execution_id,
    structured_executions.event_created_at AS event_ts,
    structured_executions.event_count AS event_count,
    structured_executions.event_source,
    structured_executions.event_type,
    SPLIT_PART(cmd_parsed_all.command_category, ' ', 2) AS command,
    cmd_parsed_all.command AS full_command,
    cmd_parsed_all.command_category,
    -- plugins
    plugins_cmd_map.plugin_name AS plugin_name,
    NULL AS parent_name,
    NULL AS executable,
    NULL AS namespace,
    NULL AS pip_url,
    NULL AS plugin_variant,
    NULL AS plugin_command,
    NULL AS plugin_type, -- extractor/loader/etc.
    plugins_cmd_map.plugin_category,
    -- projects
    structured_executions.project_id,
    projects.first_event_at AS project_created_at,
    projects.is_active AS project_is_active,
    -- environments
    cmd_parsed_all.environment AS env_id,
    hash_lookup.unhashed_value AS env_name,
    -- executions
    0 AS exit_code,
    NULL AS execution_time_ms, -- s to ms
    -- random
    NULL AS user_ipaddress,
    NULL AS meltano_version,
    NULL AS num_cpu_cores_available,
    NULL AS windows_edition,
    NULL AS machine,
    NULL AS system_release,
    NULL AS freedesktop_id,
    NULL AS freedesktop_id_like,
    NULL AS is_dev_build,
    NULL AS process_hierarchy,
    NULL AS python_version,
    NULL AS client_uuid,
    NULL AS is_ci_environment,
    NULL AS num_cpu_cores,
    NULL AS python_implementation,
    NULL AS system_name,
    NULL AS system_version,
    NULL AS exception_type,
    NULL AS exception_cause,
    NULL AS event_states,
    NULL AS event_block_types
FROM {{ ref('structured_executions') }}
LEFT JOIN
    {{ ref('cmd_parsed_all') }} ON
        structured_executions.command = cmd_parsed_all.command
LEFT JOIN {{ ref('hash_lookup') }}
    ON cmd_parsed_all.environment = hash_lookup.hash_value
LEFT JOIN
    {{ ref('projects') }} ON structured_executions.project_id = projects.project_id
LEFT JOIN
    {{ ref('plugins_cmd_map') }} ON
        structured_executions.command = plugins_cmd_map.command
WHERE cmd_parsed_all.command_type = 'plugin'
    AND plugins_cmd_map.plugin_name IS NOT NULL
