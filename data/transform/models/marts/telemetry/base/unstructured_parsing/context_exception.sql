WITH base AS (

    SELECT
        event_id,
        MAX(event_created_at) AS event_created_at,
        MAX(schema_name) AS schema_name,
        MAX(context:data:context_uuid::STRING) AS context_uuid,
        MAX(context:data:exception::STRING) AS exception
    FROM {{ ref('context_base') }}
    WHERE
        schema_name LIKE 'iglu:com.meltano/exception_context/%'
    GROUP BY 1

)

SELECT
    *,
    SPLIT_PART(schema_name, '/', -1) AS schema_version
FROM base
