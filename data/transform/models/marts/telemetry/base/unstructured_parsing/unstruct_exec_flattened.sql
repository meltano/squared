{{
    config(materialized='table')
}}

WITH plugins AS (

    SELECT
        context_uuid,
        ARRAY_AGG(DISTINCT plugin_list.value) AS plugin_list_of_lists
    FROM {{ ref('unstruct_event_flattened') }},
        LATERAL FLATTEN(input => plugins_obj) AS plugin_list
    WHERE event_name != 'telemetry_state_change_event'
    GROUP BY 1

)
SELECT
    unstruct_event_flattened.context_uuid AS execution_id,
    plugins.plugin_list_of_lists AS plugins,
    MIN(event_created_at) AS started_ts,
    MAX(event_created_at) AS finished_ts,
    MAX(user_ipaddress) AS user_ipaddress,
    MAX(project_uuid) AS project_id,
    MAX(freedesktop_version_id) AS freedesktop_version_id,
    MAX(meltano_version) AS meltano_version,
    MAX(num_cpu_cores_available) AS num_cpu_cores_available,
    MAX(windows_edition) AS windows_edition,
    MAX(command) AS cli_command,
    MAX(sub_command) AS cli_sub_command,
    MAX(machine) AS machine,
    MAX(system_release) AS system_release,
    MAX(project_uuid_source) AS project_uuid_source,
    ARRAY_AGG(options_obj) AS options_obj,
    MAX(freedesktop_id) AS freedesktop_id,
    MAX(freedesktop_id_like) AS freedesktop_id_like,
    MAX(is_dev_build) AS is_dev_build,
    MAX(process_hierarchy) AS process_hierarchy,
    MAX(python_version) AS python_version,
    MAX(environment_name_hash) AS environment_name_hash,
    MAX(client_uuid) AS client_uuid,
    MAX(is_ci_environment) AS is_ci_environment,
    MAX(num_cpu_cores) AS num_cpu_cores,
    MAX(python_implementation) AS python_implementation,
    MAX(system_name) AS system_name,
    MAX(system_version) AS system_version,
    -- Exit Event
    MAX(exit_code) AS exit_code,
    MAX(exit_timestamp) AS exit_ts,
    MAX(process_duration_microseconds) * 1.0 / 1000 AS process_duration_ms,
    -- Exception
    MAX((exception::VARIANT):type::STRING) AS exception_type,
    MAX(
        NULLIF((exception::VARIANT):cause::STRING, 'null')
    ) AS exception_cause,
    -- Tracing
    -- TODO: event states are deduped here, maybe agg differently
    ARRAY_AGG(event) AS event_states,
    ARRAY_AGG(
        DISTINCT block_type
    ) AS event_block_types,
    ARRAY_AGG(DISTINCT event_name) AS event_names
FROM {{ ref('unstruct_event_flattened') }}
LEFT JOIN plugins
    ON unstruct_event_flattened.context_uuid = plugins.context_uuid
WHERE event_name != 'telemetry_state_change_event'
GROUP BY 1, 2
