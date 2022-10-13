SELECT
    stg_snowplow__events.event_id,
    MAX(
        CASE
            WHEN
                context.value:schema::STRING
                LIKE 'iglu:com.meltano/project_context/jsonschema/%'
                THEN context.value:data:context_uuid::STRING
        END
    ) AS execution_id,
    MAX(context.value:data:project_uuid::STRING) AS project_id
FROM {{ ref('stg_snowplow__events') }},
    LATERAL FLATTEN(input => PARSE_JSON(contexts::VARIANT):data) AS context
GROUP BY 1
