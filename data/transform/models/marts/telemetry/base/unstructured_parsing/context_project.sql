WITH base AS (

    SELECT
        event_id,
        MAX(event_created_at) AS event_created_at,
        MAX(context:schema::STRING) AS schema_name,
        MAX(context:data:context_uuid::STRING) AS context_uuid,
        MAX(context:data:project_uuid::STRING) AS project_uuid,
        MAX(
            context:data:project_uuid_source::STRING
        ) AS project_uuid_source,
        MAX(
            context:data:environment_name_hash::STRING
        ) AS environment_name_hash,
        MAX(context:data:client_uuid::STRING) AS client_uuid,
        MAX(
            context:data:send_anonymous_usage_stats::BOOLEAN
        ) AS send_anonymous_usage_stats,
        MAX(
            context:data:send_anonymous_usage_stats_source::STRING
        ) AS send_anonymous_usage_stats_source
    FROM {{ ref('context_base') }}
    WHERE
        schema_name LIKE 'iglu:com.meltano/project_context/%'
    GROUP BY 1

)

SELECT
    *,
    SPLIT_PART(schema_name, '/', -1) AS schema_version
FROM base
