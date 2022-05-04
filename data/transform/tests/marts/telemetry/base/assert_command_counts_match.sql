WITH test AS (

    SELECT
        (
            SELECT COUNT(DISTINCT command)
            FROM {{ ref('events_blended') }}
        )
        - (
            SELECT COUNT(DISTINCT command)
            FROM {{ ref('event_commands_parsed') }}
        ) AS diff

)

SELECT *
FROM test
WHERE diff != 0
