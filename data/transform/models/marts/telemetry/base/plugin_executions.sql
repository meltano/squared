SELECT
    unstruct_plugin_executions.unstruct_plugin_exec_pk AS plugin_exec_pk,
    unstruct_plugin_executions.execution_id,
    unstruct_plugin_executions.started_ts AS event_ts,
    1 AS event_count,
    unstruct_plugin_executions.event_source,
    'unstructured' AS event_type,
    unstruct_plugin_executions.cli_command,
    unstruct_plugin_executions.struct_command AS full_struct_command,
    unstruct_plugin_executions.struct_command_category,
    -- plugins
    unstruct_plugin_executions.plugin_name AS plugin_name,
    unstruct_plugin_executions.parent_name AS parent_name,
    unstruct_plugin_executions.executable AS executable,
    unstruct_plugin_executions.namespace AS namespace,
    unstruct_plugin_executions.pip_url AS pip_url,
    unstruct_plugin_executions.variant_name AS plugin_variant,
    unstruct_plugin_executions.command AS plugin_command,
    unstruct_plugin_executions.plugin_type,
    unstruct_plugin_executions.plugin_category,
    unstruct_plugin_executions.plugin_surrogate_key,
    -- projects
    unstruct_plugin_executions.project_id,
    -- environments
    unstruct_plugin_executions.environment_name_hash AS env_id,
    hash_lookup.unhashed_value AS env_name,
    -- executions
    unstruct_plugin_executions.exit_code AS cli_execution_exit_code,
    unstruct_plugin_executions.process_duration_ms AS cli_execution_time_ms,
    -- random
    unstruct_plugin_executions.user_ipaddress,
    unstruct_plugin_executions.meltano_version,
    unstruct_plugin_executions.num_cpu_cores_available,
    unstruct_plugin_executions.windows_edition,
    unstruct_plugin_executions.machine,
    unstruct_plugin_executions.system_release,
    unstruct_plugin_executions.freedesktop_id,
    unstruct_plugin_executions.freedesktop_id_like,
    unstruct_plugin_executions.is_dev_build,
    unstruct_plugin_executions.process_hierarchy,
    unstruct_plugin_executions.python_version,
    unstruct_plugin_executions.client_uuid,
    unstruct_plugin_executions.is_ci_environment,
    unstruct_plugin_executions.num_cpu_cores,
    unstruct_plugin_executions.python_implementation,
    unstruct_plugin_executions.system_name,
    unstruct_plugin_executions.system_version,
    unstruct_plugin_executions.exception_type AS cli_exception_type,
    unstruct_plugin_executions.exception_cause AS cli_exception_cause,
    unstruct_plugin_executions.event_states,
    unstruct_plugin_executions.event_block_types
FROM {{ ref('unstruct_plugin_executions') }}
LEFT JOIN {{ ref('hash_lookup') }}
    ON unstruct_plugin_executions.environment_name_hash = hash_lookup.hash_value

UNION ALL

SELECT
    struct_plugin_executions.struct_plugin_exec_pk AS plugin_exec_pk,
    struct_plugin_executions.execution_id,
    struct_plugin_executions.event_created_at AS event_ts,
    struct_plugin_executions.event_count AS event_count,
    struct_plugin_executions.event_source,
    'structured' AS event_type,
    struct_plugin_executions.command,
    struct_plugin_executions.command AS full_struct_command,
    struct_plugin_executions.command_category,
    -- plugins
    struct_plugin_executions.plugin_name,
    NULL AS parent_name,
    NULL AS executable,
    NULL AS namespace,
    NULL AS pip_url,
    NULL AS plugin_variant,
    NULL AS plugin_command,
    NULL AS plugin_type, -- extractor/loader/etc.
    struct_plugin_executions.plugin_category,
    NULL AS plugin_surrogate_key,
    -- projects
    struct_plugin_executions.project_id,
    -- environments
    struct_plugin_executions.env_id,
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
FROM {{ ref('struct_plugin_executions') }}
LEFT JOIN {{ ref('hash_lookup') }}
    ON struct_plugin_executions.env_id = hash_lookup.hash_value
