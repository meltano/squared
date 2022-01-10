WITH test AS (

    SELECT
        (
            SELECT COUNT(DISTINCT command)
            FROM {{ ref('stg_ga__cli_events') }}
        )
        - (
            SELECT COUNT(DISTINCT command)
            FROM {{ ref('ga_commands_parsed') }}
        ) AS diff

)

SELECT *
FROM test
WHERE diff != 0
