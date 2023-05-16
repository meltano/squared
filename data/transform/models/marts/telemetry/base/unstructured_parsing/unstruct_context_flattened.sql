{{
    config(
        materialized='table'
    )
}}

SELECT
    event_unstruct.event_id,
    event_unstruct.event_created_at,
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
    context_environment.notable_flag_env_vars,
    context_environment.notable_hashed_env_vars,
    context_environment.python_version,
    context_environment.python_implementation,
    context_environment.system_name,
    context_environment.system_release,
    context_environment.system_version,
    context_environment.freedesktop_id,
    context_environment.freedesktop_id_like,
    context_environment.num_cpu_cores,
    context_environment.process_hierarchy,
    context_environment.parent_context_uuid,
    context_project.context_uuid,
    context_project.project_uuid,
    context_project.project_uuid_source,
    context_project.environment_name_hash,
    context_project.client_uuid,
    context_project.send_anonymous_usage_stats,
    context_project.send_anonymous_usage_stats_source
FROM {{ ref('event_unstruct') }}
LEFT JOIN {{ ref('context_cli') }}
    ON event_unstruct.event_id = context_cli.event_id
LEFT JOIN {{ ref('context_plugins') }}
    ON event_unstruct.event_id = context_plugins.event_id
LEFT JOIN {{ ref('context_exception') }}
    ON event_unstruct.event_id = context_exception.event_id
LEFT JOIN {{ ref('context_environment') }}
    ON event_unstruct.event_id = context_environment.event_id
LEFT JOIN {{ ref('context_project') }}
    ON event_unstruct.event_id = context_project.event_id
