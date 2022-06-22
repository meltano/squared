WITH base AS (
    SELECT
        unstructured_executions.*,
        plugin.value AS plugin_details
    FROM {{ ref('unstructured_executions') }},
    LATERAL FLATTEN(input => COALESCE(plugins, [''])) as plugin_list,
    LATERAL FLATTEN(input => COALESCE(plugin_list.value::variant, [''])) as plugin
)
SELECT
    {{ dbt_utils.surrogate_key(
        [
            'unstruct_plugins.plugin_name',
            'base.execution_id'
        ]
    ) }} AS plugin_usage_pk,
    base.execution_id,
    base.started_ts AS event_ts,
    1 AS event_count,
    base.event_source,
    base.event_type,
    COALESCE(base.cli_command, base.struct_command) as command,
    base.struct_comand_category,
    -- plugins
    base.plugin_details::variant AS plugin, -- REMOVE
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
    h1.unhashed_value AS env_name,
    -- executions
    base.exit_code AS exit_code,
    base.process_duration_ms AS execution_time_ms, -- s to ms
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
LEFT JOIN {{ ref('hash_lookup') }} as h1
    on base.environment_name_hash = h1.hash_value
LEFT JOIN
    {{ ref('projects') }} ON base.project_id = projects.project_id