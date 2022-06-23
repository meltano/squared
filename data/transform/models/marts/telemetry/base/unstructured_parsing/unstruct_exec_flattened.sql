with base as (
    SELECT
        stg_snowplow__events.*,
        execution_mapping.execution_id,
        execution_mapping.project_id
    FROM {{ ref('stg_snowplow__events') }}
    LEFT JOIN {{ ref('execution_mapping') }}
        ON stg_snowplow__events.event_id = execution_mapping.event_id
    where 
    event_name != 'telemetry_state_change_event'
    -- allow only struct events through that have execution ID that we can tie out with unstruct
    and execution_mapping.execution_id is not null
)
SELECT
    execution_id,
    min(base.event_created_at) as started_ts,
    max(base.event_created_at) as finish_ts,
    max(USER_IPADDRESS) as user_ipaddress,
    -- total events, last event (completed), exit event
    max(base.project_id) as project_id,
    max(context.value:data:freedesktop_version_id::string) as freedesktop_version_id,
    max(context.value:data:meltano_version::string) as meltano_version,
    max(context.value:data:num_cpu_cores_available::string) as num_cpu_cores_available,
    max(context.value:data:windows_edition::string) as windows_edition,
    max(context.value:data:command::string) as cli_command,
    max(context.value:data:sub_command::string) as cli_sub_command,
    max(context.value:data:machine::string) as machine,
    max(context.value:data:system_release::string) as system_release,
    -- TODO: missing same plugin called multiple times, undercounting total executions
    array_agg(DISTINCT context.value:data:plugins) as plugins,
    max(context.value:data:project_uuid_source::string) as project_uuid_source,
    max(context.value:data:option_keys::string) as option_keys,
    max(context.value:data:freedesktop_id::string) as freedesktop_id,
    max(context.value:data:freedesktop_id_like::string) as freedesktop_id_like,
    max(context.value:data:is_dev_build::string) as is_dev_build,
    max(context.value:data:process_hierarchy::string) as process_hierarchy,
    max(context.value:data:python_version::string) as python_version,
    max(context.value:data:environment_name_hash::string) as environment_name_hash,
    max(context.value:data:client_uuid::string) as client_uuid,
    max(context.value:data:is_ci_environment::string) as is_ci_environment,
    max(context.value:data:num_cpu_cores::string) as num_cpu_cores,
    max(context.value:data:python_implementation::string) as python_implementation,
    max(context.value:data:system_name::string) as system_name,
    max(context.value:data:system_version::string) as system_version,
    -- Exit Event
    max(parse_json(unstruct_event::variant):data:data:exit_code::string) as exit_code,
    max(parse_json(unstruct_event::variant):data:data:exit_timestamp::string) as exit_ts,
    max(parse_json(unstruct_event::variant):data:data:process_duration_microseconds::string)*1.0/1000 as process_duration_ms,
    -- Exception
    max(context.value:data:exception:type::string) as exception_type,
    max(nullif(context.value:data:exception:cause::string, 'null')) as exception_cause,
    -- Structured
    max(base.se_category) as struct_command_category,
    max(base.se_action) as struct_command,
    max(base.se_label) as struct_project_id,
    -- Tracing
    -- TODO: agg but keep counts somehow
    array_agg(distinct parse_json(unstruct_event::variant):data:data:event::string) as event_states,
    array_agg(distinct parse_json(unstruct_event::variant):data:data:type::string) as event_block_types,
    array_agg(distinct event_name) as event_names      
from base,
LATERAL FLATTEN(input => COALESCE(parse_json(contexts::variant):data, [''])) as context
group by 1
