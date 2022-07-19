WITH base AS (

    SELECT
        event_unstruct.event_id,
        event_unstruct.schema_name,
        MAX(context.value:data:context_uuid::STRING) AS context_uuid,
        MAX(
            context.value:data:freedesktop_version_id::STRING
        ) AS freedesktop_version_id,
        MAX(context.value:data:machine::STRING) AS machine,
        MAX(context.value:data:meltano_version::STRING) AS meltano_version,
        MAX(
            context.value:data:num_cpu_cores_available::STRING
        ) AS num_cpu_cores_available,
        MAX(context.value:data:windows_edition::STRING) AS windows_edition
    FROM {{ ref('event_unstruct') }},
        LATERAL FLATTEN(
            input => PARSE_JSON(event_unstruct.contexts::VARIANT):data
        ) AS context
    WHERE
        event_unstruct.schema_name LIKE 'iglu:com.meltano/environment_context/%'
        AND event_unstruct.contexts IS NOT NULL
    GROUP BY 1, 2

)

SELECT
    *,
    SPLIT_PART(schema_name, '/', -1) AS schema_version
FROM base
