WITH base AS (

    SELECT
        event_unstruct.event_id,
        MAX(context.value:schema) AS schema_name,
        MAX(context.value:data:context_uuid::STRING) AS context_uuid,
        MAX(context.value:data:project_uuid::STRING) AS project_uuid,
        MAX(
            context.value:data:project_uuid_source::STRING
        ) AS project_uuid_source,
        MAX(
            context.value:data:environment_name_hash::STRING
        ) AS environment_name_hash,
        MAX(context.value:data:client_uuid::STRING) AS client_uuid
    FROM {{ ref('event_unstruct') }},
        LATERAL FLATTEN(
            input => PARSE_JSON(event_unstruct.contexts::VARIANT):data
        ) AS context
    WHERE
        context.value:schema LIKE 'iglu:com.meltano/project_context/%'
        AND event_unstruct.contexts IS NOT NULL
    GROUP BY 1

)

SELECT
    *,
    SPLIT_PART(schema_name, '/', -1) AS schema_version
FROM base
