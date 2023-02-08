{{
    config(materialized='table')
}}

SELECT
    event_unstruct.event_id,
    context.value AS context,
    context.index AS context_index,
    context.value:schema::STRING AS schema_name
FROM {{ ref('event_unstruct') }},
    LATERAL FLATTEN(
        input => PARSE_JSON(event_unstruct.contexts::VARIANT):data
    ) AS context
WHERE event_unstruct.contexts IS NOT NULL
    AND context.value:schema::STRING
    != 'iglu:com.snowplowanalytics.snowplow/web_page/jsonschema/1-0-0'
