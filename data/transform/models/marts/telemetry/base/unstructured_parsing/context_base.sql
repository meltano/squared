{{
    config(materialized='table')
}}

SELECT
    event_unstruct.event_id,
    context.value:schema::STRING AS schema_name,
    context.value AS context,
    context.index AS index
FROM {{ ref('event_unstruct') }},
    LATERAL FLATTEN(
        input => PARSE_JSON(event_unstruct.contexts::VARIANT):data
    ) AS context
WHERE event_unstruct.contexts IS NOT NULL
