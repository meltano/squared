WITH base AS (

    SELECT
        event_id,
        event_name,
        unstruct_event,
        contexts,
        event_created_at,
        ip_address_hash,
        se_category AS legacy_se_category,
        se_action AS legacy_se_action,
        -- TODO: do we need all of these?
        se_label AS legacy_se_label,
        PARSE_JSON(
            unstruct_event::VARIANT
        ):schema AS schema_name,
        PARSE_JSON(
            unstruct_event::VARIANT
        ):data AS event_data
    FROM {{ ref('stg_snowplow__events') }}
    WHERE contexts IS NOT NULL
        AND event_created_at >= DATEADD(
            'month', -25, DATE_TRUNC('month', CURRENT_DATE)
        )

)

SELECT
    *,
    SPLIT_PART(NULLIF(schema_name, ''), '/', -1) AS schema_version
FROM base
