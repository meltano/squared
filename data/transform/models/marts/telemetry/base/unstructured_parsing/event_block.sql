WITH base AS (

    SELECT
        event_id,
        PARSE_JSON(
            unstruct_event::VARIANT
        ):data:schema::STRING AS schema_name,
        PARSE_JSON(
            unstruct_event::VARIANT
        ):data:data:type::STRING AS type,
        PARSE_JSON(
            unstruct_event::VARIANT
        ):data:data:event::STRING AS event
    FROM {{ ref('event_unstruct') }}
    WHERE
        event_name = 'block_event'

)

SELECT
    *,
    SPLIT_PART(schema_name, '/', -1) AS schema_version
FROM base
