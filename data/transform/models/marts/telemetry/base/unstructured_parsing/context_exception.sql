WITH base AS (

    SELECT
        event_unstruct.event_id,
        event_unstruct.schema_name,
        MAX(context.value:data:context_uuid::STRING) AS context_uuid,
        MAX(context.value:data:exception::STRING) AS exception
    FROM {{ ref('event_unstruct') }},
        LATERAL FLATTEN(
            input => PARSE_JSON(event_unstruct.contexts::VARIANT):data
        ) AS context
    WHERE
        context.value:schema LIKE 'iglu:com.meltano/exception_context/%'
        AND event_unstruct.contexts IS NOT NULL
    GROUP BY 1, 2

)

SELECT
    *,
    SPLIT_PART(schema_name, '/', -1) AS schema_version
FROM base
