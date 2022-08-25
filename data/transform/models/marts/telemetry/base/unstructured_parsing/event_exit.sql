WITH base AS (

    SELECT
        event_id,
        PARSE_JSON(
            unstruct_event::VARIANT
        ):data:schema::STRING AS schema_name,
        PARSE_JSON(
            unstruct_event::VARIANT
        ):data:data:exit_code::INT AS exit_code,
        PARSE_JSON(
            unstruct_event::VARIANT
        ):data:data:exit_timestamp::TIMESTAMP AS exit_timestamp,
        PARSE_JSON(
            unstruct_event::VARIANT
        ):data:data:process_duration_microseconds::INT
        AS process_duration_microseconds
    FROM {{ ref('event_unstruct') }}
    WHERE
        event_name = 'exit_event'

)

SELECT
    *,
    SPLIT_PART(schema_name, '/', -1) AS schema_version
FROM base
