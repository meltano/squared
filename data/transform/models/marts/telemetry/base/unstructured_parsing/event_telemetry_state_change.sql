WITH base AS (

    SELECT
        event_id,
        PARSE_JSON(
            unstruct_event::VARIANT
        ):data:schema::STRING AS schema_name,
        PARSE_JSON(
            unstruct_event::VARIANT
        ):data:data:changed_from::STRING AS changed_from,
        PARSE_JSON(
            unstruct_event::VARIANT
        ):data:data:changed_to::STRING AS changed_to,
        PARSE_JSON(
            unstruct_event::VARIANT
        ):data:data:setting_name::STRING AS setting_name
    FROM {{ ref('event_unstruct') }}
    WHERE
        event_name = 'telemetry_state_change_event'

)

SELECT
    *,
    SPLIT_PART(schema_name, '/', -1) AS schema_version
FROM base
