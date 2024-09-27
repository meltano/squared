{{
    config(materialized='table')
}}

WITH base AS (

    SELECT
        context_uuid,
        event_created_at,
        ip_address_hash,
        project_uuid,
        freedesktop_version_id,
        meltano_version,
        num_cpu_cores_available,
        windows_edition,
        command,
        sub_command,
        machine,
        system_release,
        project_uuid_source,
        options_obj,
        freedesktop_id,
        freedesktop_id_like,
        is_dev_build,
        process_hierarchy,
        python_version,
        environment_name_hash,
        client_uuid,
        is_ci_environment,
        notable_flag_env_vars,
        notable_hashed_env_vars,
        num_cpu_cores,
        python_implementation,
        system_name,
        system_version,
        exit_code,
        exit_timestamp,
        process_duration_microseconds,
        exception,
        event,
        block_type,
        event_name,
        plugins_obj
    FROM {{ ref('unstruct_event_flattened') }}

),

plugins AS (

    SELECT
        base.context_uuid,
        ARRAY_AGG(DISTINCT plugin_list.value) AS plugin_list_of_lists
    FROM base,
        LATERAL FLATTEN(input => plugins_obj) AS plugin_list
    WHERE base.event_name != 'telemetry_state_change_event'
    GROUP BY 1

)

SELECT
    base.context_uuid AS execution_id,
    plugins.plugin_list_of_lists AS plugins,
    MIN(base.event_created_at) AS started_ts,
    MAX(base.event_created_at) AS finished_ts,
    MAX(base.ip_address_hash) AS ip_address_hash,
    MAX(base.project_uuid) AS project_id,
    MAX(
        base.freedesktop_version_id
    ) AS freedesktop_version_id,
    MAX(base.meltano_version) AS meltano_version,
    MAX(
        base.num_cpu_cores_available
    ) AS num_cpu_cores_available,
    MAX(base.windows_edition) AS windows_edition,
    MAX(base.command) AS cli_command,
    MAX(base.sub_command) AS cli_sub_command,
    MAX(base.machine) AS machine,
    MAX(base.system_release) AS system_release,
    MAX(base.project_uuid_source) AS project_uuid_source,
    MAX(null) AS options_obj,
    -- NOTE: This is too inefficient and we're not using it much
    -- GET(
    --     ARRAY_AGG(
    --         CASE WHEN base.opt_obj_row_num = 1 THEN base.options_obj END
    --     ),
    --     0
    -- ) AS options_obj,
    MAX(base.freedesktop_id) AS freedesktop_id,
    MAX(base.freedesktop_id_like) AS freedesktop_id_like,
    MAX(base.is_dev_build) AS is_dev_build,
    MAX(base.process_hierarchy) AS process_hierarchy,
    MAX(base.python_version) AS python_version,
    MAX(
        base.environment_name_hash
    ) AS environment_name_hash,
    MAX(base.client_uuid) AS client_uuid,
    MAX(base.is_ci_environment) AS is_ci_environment,
    MAX(base.notable_flag_env_vars) AS notable_flag_env_vars,
    MAX(base.notable_hashed_env_vars) AS notable_hashed_env_vars,
    MAX(base.num_cpu_cores) AS num_cpu_cores,
    MAX(
        base.python_implementation
    ) AS python_implementation,
    MAX(base.system_name) AS system_name,
    MAX(base.system_version) AS system_version,
    -- Exit Event
    MAX(base.exit_code) AS exit_code,
    MAX(base.exit_timestamp) AS exit_ts,
    MAX(
        base.process_duration_microseconds
    ) * 1.0 / 1000 AS process_duration_ms,
    -- Exception
    MAX(
        (base.exception::VARIANT):type::STRING -- noqa: L063
    ) AS exception_type,
    MAX(
        NULLIF(
            (base.exception::VARIANT):cause::STRING, 'null' -- noqa: L063
        )
    ) AS exception_cause,
    -- Tracing
    -- NOTE: maxing out array agg 16MB limit and its not used anywhere
    -- ARRAY_AGG(base.event) AS event_states,
    ARRAY_AGG(
        DISTINCT base.block_type
    ) AS event_block_types,
    ARRAY_AGG(DISTINCT base.event_name) AS event_names
FROM base
LEFT JOIN plugins
    ON base.context_uuid = plugins.context_uuid
WHERE base.event_name != 'telemetry_state_change_event'
GROUP BY 1, 2
