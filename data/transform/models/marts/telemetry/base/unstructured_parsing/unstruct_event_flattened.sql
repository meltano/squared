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
    context_exception.exception,
    context_plugins.plugins_obj,
    context_cli.command,
    context_cli.sub_command,
    context_cli.options_obj,
    context_environment.freedesktop_version_id,
    context_environment.machine,
    context_environment.meltano_version,
    context_environment.num_cpu_cores_available,
    context_environment.windows_edition,
    context_environment.is_dev_build,
    context_environment.is_ci_environment,
    context_environment.python_version,
    context_environment.python_implementation,
    context_environment.system_name,
    context_environment.system_release,
    context_environment.system_version,
    context_environment.freedesktop_id,
    context_environment.freedesktop_id_like,
    context_environment.num_cpu_cores,
    context_environment.process_hierarchy,
    context_project.context_uuid,
    context_project.project_uuid,
    context_project.project_uuid_source,
    context_project.environment_name_hash,
    context_project.client_uuid,
    context_project.send_anonymous_usage_stats,
    context_project.send_anonymous_usage_stats_source
FROM {{ ref('event_cli') }}
LEFT JOIN {{ ref('context_cli') }}
    ON event_cli.event_id = context_cli.event_id
LEFT JOIN {{ ref('context_plugins') }}
    ON event_cli.event_id = context_plugins.event_id
LEFT JOIN {{ ref('context_exception') }}
    ON event_cli.event_id = context_exception.event_id
LEFT JOIN {{ ref('context_environment') }}
    ON event_cli.event_id = context_environment.event_id
LEFT JOIN {{ ref('context_project') }}
    ON event_cli.event_id = context_project.event_id

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
    context_exception.exception,
    context_plugins.plugins_obj,
    context_cli.command,
    context_cli.sub_command,
    context_cli.options_obj,
    context_environment.freedesktop_version_id,
    context_environment.machine,
    context_environment.meltano_version,
    context_environment.num_cpu_cores_available,
    context_environment.windows_edition,
    context_environment.is_dev_build,
    context_environment.is_ci_environment,
    context_environment.python_version,
    context_environment.python_implementation,
    context_environment.system_name,
    context_environment.system_release,
    context_environment.system_version,
    context_environment.freedesktop_id,
    context_environment.freedesktop_id_like,
    context_environment.num_cpu_cores,
    context_environment.process_hierarchy,
    context_project.context_uuid,
    context_project.project_uuid,
    context_project.project_uuid_source,
    context_project.environment_name_hash,
    context_project.client_uuid,
    context_project.send_anonymous_usage_stats,
    context_project.send_anonymous_usage_stats_source
FROM {{ ref('event_block') }}
LEFT JOIN {{ ref('context_cli') }}
    ON event_block.event_id = context_cli.event_id
LEFT JOIN {{ ref('context_plugins') }}
    ON event_block.event_id = context_plugins.event_id
LEFT JOIN {{ ref('context_exception') }}
    ON event_block.event_id = context_exception.event_id
LEFT JOIN {{ ref('context_environment') }}
    ON event_block.event_id = context_environment.event_id
LEFT JOIN {{ ref('context_project') }}
    ON event_block.event_id = context_project.event_id

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
    context_exception.exception,
    context_plugins.plugins_obj,
    context_cli.command,
    context_cli.sub_command,
    context_cli.options_obj,
    context_environment.freedesktop_version_id,
    context_environment.machine,
    context_environment.meltano_version,
    context_environment.num_cpu_cores_available,
    context_environment.windows_edition,
    context_environment.is_dev_build,
    context_environment.is_ci_environment,
    context_environment.python_version,
    context_environment.python_implementation,
    context_environment.system_name,
    context_environment.system_release,
    context_environment.system_version,
    context_environment.freedesktop_id,
    context_environment.freedesktop_id_like,
    context_environment.num_cpu_cores,
    context_environment.process_hierarchy,
    context_project.context_uuid,
    context_project.project_uuid,
    context_project.project_uuid_source,
    context_project.environment_name_hash,
    context_project.client_uuid,
    context_project.send_anonymous_usage_stats,
    context_project.send_anonymous_usage_stats_source
FROM {{ ref('event_exit') }}
LEFT JOIN {{ ref('context_cli') }}
    ON event_exit.event_id = context_cli.event_id
LEFT JOIN {{ ref('context_plugins') }}
    ON event_exit.event_id = context_plugins.event_id
LEFT JOIN {{ ref('context_exception') }}
    ON event_exit.event_id = context_exception.event_id
LEFT JOIN {{ ref('context_environment') }}
    ON event_exit.event_id = context_environment.event_id
LEFT JOIN {{ ref('context_project') }}
    ON event_exit.event_id = context_project.event_id

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
    context_exception.exception,
    context_plugins.plugins_obj,
    context_cli.command,
    context_cli.sub_command,
    context_cli.options_obj,
    context_environment.freedesktop_version_id,
    context_environment.machine,
    context_environment.meltano_version,
    context_environment.num_cpu_cores_available,
    context_environment.windows_edition,
    context_environment.is_dev_build,
    context_environment.is_ci_environment,
    context_environment.python_version,
    context_environment.python_implementation,
    context_environment.system_name,
    context_environment.system_release,
    context_environment.system_version,
    context_environment.freedesktop_id,
    context_environment.freedesktop_id_like,
    context_environment.num_cpu_cores,
    context_environment.process_hierarchy,
    context_project.context_uuid,
    context_project.project_uuid,
    context_project.project_uuid_source,
    context_project.environment_name_hash,
    context_project.client_uuid,
    context_project.send_anonymous_usage_stats,
    context_project.send_anonymous_usage_stats_source
FROM {{ ref('event_telemetry_state_change') }}
LEFT JOIN {{ ref('context_cli') }}
    ON event_telemetry_state_change.event_id = context_cli.event_id
LEFT JOIN {{ ref('context_plugins') }}
    ON event_telemetry_state_change.event_id = context_plugins.event_id
LEFT JOIN {{ ref('context_exception') }}
    ON event_telemetry_state_change.event_id = context_exception.event_id
LEFT JOIN {{ ref('context_environment') }}
    ON event_telemetry_state_change.event_id = context_environment.event_id
LEFT JOIN {{ ref('context_project') }}
    ON event_telemetry_state_change.event_id = context_project.event_id
-- The original implementation didn't have a project_uuid so they aren't
-- useful for anything and should be excluded.
WHERE context_project.project_uuid IS NOT NULL

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
    context_exception.exception,
    context_plugins.plugins_obj,
    SPLIT_PART(
        event_legacy_with_context.legacy_se_category,
        ' ',
        2
    ) AS command,
    NULL AS sub_command,
    context_cli.options_obj,
    context_environment.freedesktop_version_id,
    context_environment.machine,
    context_environment.meltano_version,
    context_environment.num_cpu_cores_available,
    context_environment.windows_edition,
    context_environment.is_dev_build,
    context_environment.is_ci_environment,
    context_environment.python_version,
    context_environment.python_implementation,
    context_environment.system_name,
    context_environment.system_release,
    context_environment.system_version,
    context_environment.freedesktop_id,
    context_environment.freedesktop_id_like,
    context_environment.num_cpu_cores,
    context_environment.process_hierarchy,
    context_project.context_uuid,
    context_project.project_uuid,
    context_project.project_uuid_source,
    context_project.environment_name_hash,
    context_project.client_uuid,
    context_project.send_anonymous_usage_stats,
    context_project.send_anonymous_usage_stats_source
FROM {{ ref('event_legacy_with_context') }}
LEFT JOIN {{ ref('context_cli') }}
    ON event_legacy_with_context.event_id = context_cli.event_id
LEFT JOIN {{ ref('context_plugins') }}
    ON event_legacy_with_context.event_id = context_plugins.event_id
LEFT JOIN {{ ref('context_exception') }}
    ON event_legacy_with_context.event_id = context_exception.event_id
LEFT JOIN {{ ref('context_environment') }}
    ON event_legacy_with_context.event_id = context_environment.event_id
LEFT JOIN {{ ref('context_project') }}
    ON event_legacy_with_context.event_id = context_project.event_id
