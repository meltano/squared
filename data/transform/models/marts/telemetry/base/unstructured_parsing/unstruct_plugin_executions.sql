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
    ) }} AS unstruct_plugin_exec_pk,
    base.execution_id,
    base.started_ts AS event_ts,
    1 AS event_count,
    base.event_source,
    'unstructured' AS event_type,
    base.cli_command,
    base.struct_command AS full_struct_command,
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
    unstruct_plugins.plugin_surrogate_key,
    -- projects
    base.project_id,
    -- environments
    base.environment_name_hash AS env_id,
    -- executions
    base.exit_code AS cli_execution_exit_code,
    base.process_duration_ms AS cli_execution_time_ms,
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
    base.exception_type AS cli_exception_type,
    base.exception_cause AS cli_exception_cause,
    base.event_states,
    base.event_block_types
FROM base
LEFT JOIN {{ ref('unstruct_plugins') }}
    ON unstruct_plugins.plugin_surrogate_key = {{ dbt_utils.surrogate_key(
        ['base.plugin_details']
    ) }}
