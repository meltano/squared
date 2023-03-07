{{
    config(materialized='table')
}}

SELECT
    event_cli.event_created_at,
    event_cli.ip_address_hash,
    event_cli.event_id,
    event_cli.event,
    event_cli.event_name,
    NULL AS block_type,
    NULL AS exit_code,
    NULL AS exit_timestamp,
    NULL AS process_duration_microseconds,
    NULL AS changed_from,
    NULL AS changed_to,
    NULL AS setting_name,
    unstruct_context_flattened.exception,
    unstruct_context_flattened.plugins_obj,
    unstruct_context_flattened.command,
    unstruct_context_flattened.sub_command,
    unstruct_context_flattened.options_obj,
    unstruct_context_flattened.freedesktop_version_id,
    unstruct_context_flattened.machine,
    unstruct_context_flattened.meltano_version,
    unstruct_context_flattened.num_cpu_cores_available,
    unstruct_context_flattened.windows_edition,
    unstruct_context_flattened.is_dev_build,
    unstruct_context_flattened.is_ci_environment,
    unstruct_context_flattened.python_version,
    unstruct_context_flattened.python_implementation,
    unstruct_context_flattened.system_name,
    unstruct_context_flattened.system_release,
    unstruct_context_flattened.system_version,
    unstruct_context_flattened.freedesktop_id,
    unstruct_context_flattened.freedesktop_id_like,
    unstruct_context_flattened.num_cpu_cores,
    unstruct_context_flattened.process_hierarchy,
    unstruct_context_flattened.parent_context_uuid,
    unstruct_context_flattened.context_uuid,
    unstruct_context_flattened.project_uuid,
    unstruct_context_flattened.project_uuid_source,
    unstruct_context_flattened.environment_name_hash,
    unstruct_context_flattened.client_uuid,
    unstruct_context_flattened.send_anonymous_usage_stats,
    unstruct_context_flattened.send_anonymous_usage_stats_source
FROM {{ ref('event_cli') }}
LEFT JOIN {{ ref('unstruct_context_flattened') }}
    ON event_cli.event_id = unstruct_context_flattened.event_id

UNION ALL

SELECT
    event_block.event_created_at,
    event_block.ip_address_hash,
    event_block.event_id,
    event_block.event,
    event_block.event_name,
    event_block.block_type,
    NULL AS exit_code,
    NULL AS exit_timestamp,
    NULL AS process_duration_microseconds,
    NULL AS changed_from,
    NULL AS changed_to,
    NULL AS setting_name,
    unstruct_context_flattened.exception,
    unstruct_context_flattened.plugins_obj,
    unstruct_context_flattened.command,
    unstruct_context_flattened.sub_command,
    unstruct_context_flattened.options_obj,
    unstruct_context_flattened.freedesktop_version_id,
    unstruct_context_flattened.machine,
    unstruct_context_flattened.meltano_version,
    unstruct_context_flattened.num_cpu_cores_available,
    unstruct_context_flattened.windows_edition,
    unstruct_context_flattened.is_dev_build,
    unstruct_context_flattened.is_ci_environment,
    unstruct_context_flattened.python_version,
    unstruct_context_flattened.python_implementation,
    unstruct_context_flattened.system_name,
    unstruct_context_flattened.system_release,
    unstruct_context_flattened.system_version,
    unstruct_context_flattened.freedesktop_id,
    unstruct_context_flattened.freedesktop_id_like,
    unstruct_context_flattened.num_cpu_cores,
    unstruct_context_flattened.process_hierarchy,
    unstruct_context_flattened.parent_context_uuid,
    unstruct_context_flattened.context_uuid,
    unstruct_context_flattened.project_uuid,
    unstruct_context_flattened.project_uuid_source,
    unstruct_context_flattened.environment_name_hash,
    unstruct_context_flattened.client_uuid,
    unstruct_context_flattened.send_anonymous_usage_stats,
    unstruct_context_flattened.send_anonymous_usage_stats_source
FROM {{ ref('event_block') }}
LEFT JOIN {{ ref('unstruct_context_flattened') }}
    ON event_block.event_id = unstruct_context_flattened.event_id

UNION ALL

SELECT
    event_exit.event_created_at,
    event_exit.ip_address_hash,
    event_exit.event_id,
    event_exit.event,
    event_exit.event_name,
    NULL AS block_type,
    event_exit.exit_code,
    event_exit.exit_timestamp,
    event_exit.process_duration_microseconds,
    NULL AS changed_from,
    NULL AS changed_to,
    NULL AS setting_name,
    unstruct_context_flattened.exception,
    unstruct_context_flattened.plugins_obj,
    unstruct_context_flattened.command,
    unstruct_context_flattened.sub_command,
    unstruct_context_flattened.options_obj,
    unstruct_context_flattened.freedesktop_version_id,
    unstruct_context_flattened.machine,
    unstruct_context_flattened.meltano_version,
    unstruct_context_flattened.num_cpu_cores_available,
    unstruct_context_flattened.windows_edition,
    unstruct_context_flattened.is_dev_build,
    unstruct_context_flattened.is_ci_environment,
    unstruct_context_flattened.python_version,
    unstruct_context_flattened.python_implementation,
    unstruct_context_flattened.system_name,
    unstruct_context_flattened.system_release,
    unstruct_context_flattened.system_version,
    unstruct_context_flattened.freedesktop_id,
    unstruct_context_flattened.freedesktop_id_like,
    unstruct_context_flattened.num_cpu_cores,
    unstruct_context_flattened.process_hierarchy,
    unstruct_context_flattened.parent_context_uuid,
    unstruct_context_flattened.context_uuid,
    unstruct_context_flattened.project_uuid,
    unstruct_context_flattened.project_uuid_source,
    unstruct_context_flattened.environment_name_hash,
    unstruct_context_flattened.client_uuid,
    unstruct_context_flattened.send_anonymous_usage_stats,
    unstruct_context_flattened.send_anonymous_usage_stats_source
FROM {{ ref('event_exit') }}
LEFT JOIN {{ ref('unstruct_context_flattened') }}
    ON event_exit.event_id = unstruct_context_flattened.event_id

UNION ALL

SELECT
    event_telemetry_state_change.event_created_at,
    event_telemetry_state_change.ip_address_hash,
    event_telemetry_state_change.event_id,
    event_telemetry_state_change.event,
    event_telemetry_state_change.event_name,
    NULL AS block_type,
    NULL AS exit_code,
    NULL AS exit_timestamp,
    NULL AS process_duration_microseconds,
    event_telemetry_state_change.changed_from,
    event_telemetry_state_change.changed_to,
    event_telemetry_state_change.setting_name,
    unstruct_context_flattened.exception,
    unstruct_context_flattened.plugins_obj,
    unstruct_context_flattened.command,
    unstruct_context_flattened.sub_command,
    unstruct_context_flattened.options_obj,
    unstruct_context_flattened.freedesktop_version_id,
    unstruct_context_flattened.machine,
    unstruct_context_flattened.meltano_version,
    unstruct_context_flattened.num_cpu_cores_available,
    unstruct_context_flattened.windows_edition,
    unstruct_context_flattened.is_dev_build,
    unstruct_context_flattened.is_ci_environment,
    unstruct_context_flattened.python_version,
    unstruct_context_flattened.python_implementation,
    unstruct_context_flattened.system_name,
    unstruct_context_flattened.system_release,
    unstruct_context_flattened.system_version,
    unstruct_context_flattened.freedesktop_id,
    unstruct_context_flattened.freedesktop_id_like,
    unstruct_context_flattened.num_cpu_cores,
    unstruct_context_flattened.process_hierarchy,
    unstruct_context_flattened.parent_context_uuid,
    unstruct_context_flattened.context_uuid,
    unstruct_context_flattened.project_uuid,
    unstruct_context_flattened.project_uuid_source,
    unstruct_context_flattened.environment_name_hash,
    unstruct_context_flattened.client_uuid,
    unstruct_context_flattened.send_anonymous_usage_stats,
    unstruct_context_flattened.send_anonymous_usage_stats_source
FROM {{ ref('event_telemetry_state_change') }}
LEFT JOIN {{ ref('unstruct_context_flattened') }}
    ON
        event_telemetry_state_change.event_id
        = unstruct_context_flattened.event_id
-- The original implementation didn't have a project_uuid so they aren't
-- useful for anything and should be excluded.
WHERE unstruct_context_flattened.project_uuid IS NOT NULL

UNION ALL

SELECT
    event_legacy_with_context.event_created_at,
    event_legacy_with_context.ip_address_hash,
    event_legacy_with_context.event_id,
    NULL AS event,
    event_legacy_with_context.event_name,
    NULL AS block_type,
    NULL AS exit_code,
    NULL AS exit_timestamp,
    NULL AS process_duration_microseconds,
    NULL AS changed_from,
    NULL AS changed_to,
    NULL AS setting_name,
    unstruct_context_flattened.exception,
    unstruct_context_flattened.plugins_obj,
    SPLIT_PART(
        event_legacy_with_context.legacy_se_category,
        ' ',
        2
    ) AS command,
    NULL AS sub_command,
    unstruct_context_flattened.options_obj,
    unstruct_context_flattened.freedesktop_version_id,
    unstruct_context_flattened.machine,
    unstruct_context_flattened.meltano_version,
    unstruct_context_flattened.num_cpu_cores_available,
    unstruct_context_flattened.windows_edition,
    unstruct_context_flattened.is_dev_build,
    unstruct_context_flattened.is_ci_environment,
    unstruct_context_flattened.python_version,
    unstruct_context_flattened.python_implementation,
    unstruct_context_flattened.system_name,
    unstruct_context_flattened.system_release,
    unstruct_context_flattened.system_version,
    unstruct_context_flattened.freedesktop_id,
    unstruct_context_flattened.freedesktop_id_like,
    unstruct_context_flattened.num_cpu_cores,
    unstruct_context_flattened.process_hierarchy,
    unstruct_context_flattened.parent_context_uuid,
    unstruct_context_flattened.context_uuid,
    unstruct_context_flattened.project_uuid,
    unstruct_context_flattened.project_uuid_source,
    unstruct_context_flattened.environment_name_hash,
    unstruct_context_flattened.client_uuid,
    unstruct_context_flattened.send_anonymous_usage_stats,
    unstruct_context_flattened.send_anonymous_usage_stats_source
FROM {{ ref('event_legacy_with_context') }}
LEFT JOIN {{ ref('unstruct_context_flattened') }}
    ON event_legacy_with_context.event_id = unstruct_context_flattened.event_id
