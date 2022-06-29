WITH test AS (

    SELECT
        (
            SELECT COUNT(DISTINCT command)
            FROM {{ ref('structured_executions') }}
        )
        - (
            SELECT COUNT(DISTINCT command)
            FROM {{ ref('event_commands_parsed') }}
        ) AS diff

)

SELECT *
FROM test
WHERE diff != 0
