WITH base AS (

    SELECT
        event_id,
        event_name,
        unstruct_event,
        contexts,
        event_created_at,
        user_ipaddress,
        PARSE_JSON(
            unstruct_event::VARIANT
        ):schema AS schema_name,
        PARSE_JSON(
            unstruct_event::VARIANT
        ):data AS event_data
    FROM {{ ref('stg_snowplow__events') }}
    WHERE event = 'unstruct'
    AND event_created_at >= DATEADD('month', -25, DATE_TRUNC('month', CURRENT_DATE))

)

SELECT
    *,
    SPLIT_PART(schema_name, '/', -1) AS schema_version
FROM base
