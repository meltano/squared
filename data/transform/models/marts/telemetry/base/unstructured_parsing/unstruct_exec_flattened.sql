WITH base AS (
    SELECT
        stg_snowplow__events.*,
        execution_mapping.execution_id,
        execution_mapping.project_id
    FROM {{ ref('stg_snowplow__events') }}
    LEFT JOIN {{ ref('execution_mapping') }}
        ON stg_snowplow__events.event_id = execution_mapping.event_id
    WHERE
        stg_snowplow__events.event_name != 'telemetry_state_change_event'
        -- Allow only events with an execution ID, this includes struct
        -- events that have the new contexts attached.
        AND execution_mapping.execution_id IS NOT NULL
)

SELECT
    base.execution_id,
    MIN(base.event_created_at) AS started_ts,
    MAX(base.event_created_at) AS finish_ts,
    MAX(base.user_ipaddress) AS user_ipaddress,
    MAX(base.project_id) AS project_id,
    MAX(
        context.value:data:freedesktop_version_id::STRING
    ) AS freedesktop_version_id,
    MAX(context.value:data:meltano_version::STRING) AS meltano_version,
    MAX(
        context.value:data:num_cpu_cores_available::STRING
    ) AS num_cpu_cores_available,
    MAX(context.value:data:windows_edition::STRING) AS windows_edition,
    COALESCE(
        MAX(
            context.value:data:command::STRING
        ),
        SPLIT_PART(
            MAX(base.se_category),
            ' ',
            2
        )
    ) AS cli_command,
    MAX(context.value:data:sub_command::STRING) AS cli_sub_command,
    MAX(context.value:data:machine::STRING) AS machine,
    MAX(context.value:data:system_release::STRING) AS system_release,
    -- TODO: plugins list is deduped so this will undercount executions
    ARRAY_AGG(DISTINCT context.value:data:plugins) AS plugins,
    MAX(context.value:data:project_uuid_source::STRING) AS project_uuid_source,
    MAX(context.value:data:option_keys::STRING) AS option_keys,
    MAX(context.value:data:freedesktop_id::STRING) AS freedesktop_id,
    MAX(context.value:data:freedesktop_id_like::STRING) AS freedesktop_id_like,
    MAX(context.value:data:is_dev_build::STRING) AS is_dev_build,
    MAX(context.value:data:process_hierarchy::STRING) AS process_hierarchy,
    MAX(context.value:data:python_version::STRING) AS python_version,
    MAX(
        context.value:data:environment_name_hash::STRING
    ) AS environment_name_hash,
    MAX(context.value:data:client_uuid::STRING) AS client_uuid,
    MAX(context.value:data:is_ci_environment::STRING) AS is_ci_environment,
    MAX(context.value:data:num_cpu_cores::STRING) AS num_cpu_cores,
    MAX(
        context.value:data:python_implementation::STRING
    ) AS python_implementation,
    MAX(context.value:data:system_name::STRING) AS system_name,
    MAX(context.value:data:system_version::STRING) AS system_version,
    -- Exit Event
    MAX(
        PARSE_JSON(
            base.unstruct_event::VARIANT
        ):data:data:exit_code::STRING
    ) AS exit_code,
    MAX(
        PARSE_JSON(
            base.unstruct_event::VARIANT
        ):data:data:exit_timestamp::STRING
    ) AS exit_ts,
    MAX(
        PARSE_JSON(
            base.unstruct_event::VARIANT
        ):data:data:process_duration_microseconds::STRING
    ) * 1.0 / 1000 AS process_duration_ms,
    -- Exception
    MAX(context.value:data:exception:type::STRING) AS exception_type,
    MAX(
        NULLIF(context.value:data:exception:cause::STRING, 'null')
    ) AS exception_cause,
    -- Structured
    MAX(base.se_category) AS struct_command_category,
    MAX(base.se_action) AS struct_command,
    MAX(base.se_label) AS struct_project_id,
    -- Tracing
    -- TODO: event states are deduped here, maybe agg differently
    ARRAY_AGG(
        DISTINCT PARSE_JSON(
            base.unstruct_event::VARIANT
        ):data:data:event::STRING
    ) AS event_states,
    ARRAY_AGG(
        DISTINCT PARSE_JSON(base.unstruct_event::VARIANT):data:data:type::STRING
    ) AS event_block_types,
    ARRAY_AGG(DISTINCT base.event_name) AS event_names
FROM base,
    LATERAL FLATTEN(
        input => COALESCE(PARSE_JSON(contexts::VARIANT):data, [''])
    ) AS context
GROUP BY 1
