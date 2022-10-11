{{
    config(materialized='table')
}}

SELECT
    stg_snowplow__events.event_created_at,
    stg_snowplow__events.user_ipaddress,
    event_cli.event_id,
    event_cli.event,
    NULL AS block_type,
    context_exception.exception,
    context_plugins.plugins_obj,
    NULL AS exit_code,
    NULL AS exit_timestamp,
    NULL AS process_duration_microseconds,
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
    context_project.send_anonymous_usage_stats_source,
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
LEFT JOIN {{ ref('stg_snowplow__events') }}
    ON event_cli.event_id = stg_snowplow__events.event_id

UNION ALL

SELECT
    stg_snowplow__events.event_created_at,
    stg_snowplow__events.user_ipaddress,
    event_block.event_id,
    event_block.event,
    event_block.block_type,
    context_exception.exception,
    context_plugins.plugins_obj,
    NULL AS exit_code,
    NULL AS exit_timestamp,
    NULL AS process_duration_microseconds,
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
LEFT JOIN {{ ref('stg_snowplow__events') }}
    ON event_block.event_id = stg_snowplow__events.event_id

UNION ALL

SELECT
    stg_snowplow__events.event_created_at,
    stg_snowplow__events.user_ipaddress,
    event_exit.event_id,
    event_exit.event,
    NULL AS block_type,
    context_exception.exception,
    context_plugins.plugins_obj,
    event_exit.exit_code,
    event_exit.exit_timestamp,
    event_exit.process_duration_microseconds,
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
LEFT JOIN {{ ref('stg_snowplow__events') }}
    ON event_exit.event_id = stg_snowplow__events.event_id
