WITH test AS (

    SELECT
        (
            SELECT COUNT(*)
            FROM {{ ref('cli_executions') }}
        )
        - (
            SELECT
                (
                    SELECT COUNT(*)
                    FROM {{ ref('structured_executions') }}
                )
                + (
                    SELECT COUNT(*)
                    FROM {{ ref('unstructured_executions') }}
                )
        ) AS diff

)

SELECT *
FROM test
WHERE diff != 0
