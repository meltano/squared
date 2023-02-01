WITH base AS (

    SELECT
        event_id,
        MAX(schema_name) AS schema_name,
        MAX(context:data:context_uuid::STRING) AS context_uuid,
        MAX(context:data:parent_context_uuid::STRING) AS parent_context_uuid,
        MAX(
            context:data:freedesktop_version_id::STRING
        ) AS freedesktop_version_id,
        MAX(context:data:machine::STRING) AS machine,
        MAX(context:data:meltano_version::STRING) AS meltano_version,
        MAX(
            context:data:num_cpu_cores_available::STRING
        ) AS num_cpu_cores_available,
        MAX(context:data:windows_edition::STRING) AS windows_edition,
        MAX(context:data:is_dev_build::STRING) AS is_dev_build,
        MAX(context:data:is_ci_environment::STRING) AS is_ci_environment,
        MAX(context:data:notable_flag_env_vars) AS notable_flag_env_vars,
        MAX(context:data:python_version::STRING) AS python_version,
        MAX(
            context:data:python_implementation::STRING
        ) AS python_implementation,
        MAX(context:data:system_name::STRING) AS system_name,
        MAX(context:data:system_release::STRING) AS system_release,
        MAX(context:data:system_version::STRING) AS system_version,
        MAX(context:data:freedesktop_id::STRING) AS freedesktop_id,
        MAX(context:data:freedesktop_id_like::STRING) AS freedesktop_id_like,
        MAX(context:data:num_cpu_cores::STRING) AS num_cpu_cores,
        MAX(context:data:process_hierarchy) AS process_hierarchy
    FROM {{ ref('context_base') }}
    WHERE
        schema_name LIKE 'iglu:com.meltano/environment_context/%'
    GROUP BY 1

)

SELECT
    *,
    SPLIT_PART(schema_name, '/', -1) AS schema_version
FROM base
