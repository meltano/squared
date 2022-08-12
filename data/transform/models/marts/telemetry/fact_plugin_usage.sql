SELECT
    plugin_executions.plugin_exec_pk,
    plugin_executions.execution_id,
    plugin_executions.plugin_started,
    plugin_executions.plugin_ended,
    plugin_executions.plugin_runtime_ms,
    plugin_executions.completion_status,
    plugin_executions.event_count,
    plugin_executions.event_source,
    plugin_executions.event_type,
    plugin_executions.plugin_name,
    plugin_executions.parent_name,
    plugin_executions.executable,
    plugin_executions.namespace,
    plugin_executions.pip_url,
    plugin_executions.plugin_variant,
    plugin_executions.plugin_command,
    plugin_executions.plugin_type,
    plugin_executions.plugin_category,
    plugin_executions.plugin_surrogate_key,
    -- CLI Attributes
    cli_executions_base.cli_command,
    cli_executions_base.environment_name_hash AS env_id,
    hash_lookup.unhashed_value AS env_name,
    cli_executions_base.exit_code AS cli_exit_code,
    cli_executions_base.meltano_version,
    cli_executions_base.num_cpu_cores_available,
    cli_executions_base.windows_edition,
    cli_executions_base.machine,
    cli_executions_base.system_release,
    cli_executions_base.is_dev_build,
    cli_executions_base.python_version,
    cli_executions_base.is_ci_environment,
    cli_executions_base.python_implementation,
    cli_executions_base.system_name,
    cli_executions_base.system_version,
    project_dim.project_id,
    project_dim.first_event_at AS project_created_at,
    -- Project Attributes
    project_dim.is_active AS project_is_active,
    project_dim.project_id_source,
    ip_address_dim.cloud_provider,
    ip_address_dim.execution_location,
    -- Host Attributes
    ip_address_dim.ip_address_hash,
    COALESCE(
        cli_executions_base.started_ts, cli_executions_base.event_created_at
    ) AS cli_started_ts,
    DATEDIFF(
        MILLISECOND,
        cli_executions_base.started_ts,
        cli_executions_base.finish_ts
    ) AS cli_processing_ms
FROM {{ ref('plugin_executions') }}
LEFT JOIN {{ ref('cli_executions_base') }}
    ON plugin_executions.execution_id = cli_executions_base.execution_id
LEFT JOIN {{ ref('project_dim') }}
    ON cli_executions_base.project_id = project_dim.project_id
LEFT JOIN {{ ref('ip_address_dim') }}
    ON cli_executions_base.ip_address_hash = ip_address_dim.ip_address_hash
        AND COALESCE(cli_executions_base.event_created_at
            < ip_address_dim.active_to, TRUE)
-- TODO: move this parsing up stream
LEFT JOIN {{ ref('hash_lookup') }}
    ON cli_executions_base.environment_name_hash = hash_lookup.hash_value
        AND hash_lookup.category = 'environment'
