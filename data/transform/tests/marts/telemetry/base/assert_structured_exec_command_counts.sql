WITH test AS (

    SELECT
        (
            SELECT COUNT(DISTINCT command)
            FROM {{ ref('structured_executions') }}
        )
        - (
            SELECT COUNT(DISTINCT command)
            FROM {{ ref('cmd_parsed_all') }}
        ) AS diff

)

SELECT *
FROM test
WHERE diff != 0
