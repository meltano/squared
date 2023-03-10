{{
    config(
        materialized='incremental',
        cluster_by=['event_id']
    )
}}

SELECT
    event_unstruct.event_id,
    event_unstruct.event_created_at,
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

{% if is_incremental() %}

AND event_unstruct.event_created_at >= (
    SELECT DATEADD(days, -1, MAX(event_created_at)) FROM {{ this }}
)
AND event_unstruct.event_id NOT IN (SELECT event_id FROM {{ this }}) 

{% endif %}
