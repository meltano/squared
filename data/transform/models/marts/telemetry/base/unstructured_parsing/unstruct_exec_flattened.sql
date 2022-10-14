{{
    config(materialized='table')
}}

WITH plugins AS (

    SELECT
        unstruct_event_flattened.context_uuid,
        ARRAY_AGG(DISTINCT plugin_list.value) AS plugin_list_of_lists
    FROM {{ ref('unstruct_event_flattened') }},
        LATERAL FLATTEN(input => plugins_obj) AS plugin_list
    WHERE unstruct_event_flattened.event_name != 'telemetry_state_change_event'
    GROUP BY 1

)

SELECT
    unstruct_event_flattened.context_uuid AS execution_id,
    plugins.plugin_list_of_lists AS plugins,
    MIN(unstruct_event_flattened.event_created_at) AS started_ts,
    MAX(unstruct_event_flattened.event_created_at) AS finished_ts,
    MAX(unstruct_event_flattened.user_ipaddress) AS user_ipaddress,
    MAX(unstruct_event_flattened.project_uuid) AS project_id,
    MAX(
        unstruct_event_flattened.freedesktop_version_id
    ) AS freedesktop_version_id,
    MAX(unstruct_event_flattened.meltano_version) AS meltano_version,
    MAX(
        unstruct_event_flattened.num_cpu_cores_available
    ) AS num_cpu_cores_available,
    MAX(unstruct_event_flattened.windows_edition) AS windows_edition,
    MAX(unstruct_event_flattened.command) AS cli_command,
    MAX(unstruct_event_flattened.sub_command) AS cli_sub_command,
    MAX(unstruct_event_flattened.machine) AS machine,
    MAX(unstruct_event_flattened.system_release) AS system_release,
    MAX(unstruct_event_flattened.project_uuid_source) AS project_uuid_source,
    ARRAY_AGG(unstruct_event_flattened.options_obj) AS options_obj,
    MAX(unstruct_event_flattened.freedesktop_id) AS freedesktop_id,
    MAX(unstruct_event_flattened.freedesktop_id_like) AS freedesktop_id_like,
    MAX(unstruct_event_flattened.is_dev_build) AS is_dev_build,
    MAX(unstruct_event_flattened.process_hierarchy) AS process_hierarchy,
    MAX(unstruct_event_flattened.python_version) AS python_version,
    MAX(
        unstruct_event_flattened.environment_name_hash
    ) AS environment_name_hash,
    MAX(unstruct_event_flattened.client_uuid) AS client_uuid,
    MAX(unstruct_event_flattened.is_ci_environment) AS is_ci_environment,
    MAX(unstruct_event_flattened.num_cpu_cores) AS num_cpu_cores,
    MAX(
        unstruct_event_flattened.python_implementation
    ) AS python_implementation,
    MAX(unstruct_event_flattened.system_name) AS system_name,
    MAX(unstruct_event_flattened.system_version) AS system_version,
    -- Exit Event
    MAX(unstruct_event_flattened.exit_code) AS exit_code,
    MAX(unstruct_event_flattened.exit_timestamp) AS exit_ts,
    MAX(
        unstruct_event_flattened.process_duration_microseconds
    ) * 1.0 / 1000 AS process_duration_ms,
    -- Exception
    MAX(
        (unstruct_event_flattened.exception::VARIANT):type::STRING
    ) AS exception_type,
    MAX(
        NULLIF(
            (unstruct_event_flattened.exception::VARIANT):cause::STRING, 'null'
        )
    ) AS exception_cause,
    -- Tracing
    -- TODO: event states are deduped here, maybe agg differently
    ARRAY_AGG(unstruct_event_flattened.event) AS event_states,
    ARRAY_AGG(
        DISTINCT unstruct_event_flattened.block_type
    ) AS event_block_types,
    ARRAY_AGG(DISTINCT unstruct_event_flattened.event_name) AS event_names
FROM {{ ref('unstruct_event_flattened') }}
LEFT JOIN plugins
    ON unstruct_event_flattened.context_uuid = plugins.context_uuid
WHERE unstruct_event_flattened.event_name != 'telemetry_state_change_event'
GROUP BY 1, 2
