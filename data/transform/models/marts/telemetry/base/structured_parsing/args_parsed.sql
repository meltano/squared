SELECT
    unique_commands.command,
    SPLIT_PART(
        SPLIT_PART(unique_commands.command, '--environment=', 2), ' ', 1
    ) AS environment,
    ARRAY_AGG(
        CASE
            WHEN
                flat.value::STRING LIKE '--%'
                AND flat.value::STRING NOT LIKE '--environment=%'
                THEN flat.value::STRING
        END
    ) AS args
FROM
    {{ ref('unique_commands') }},
    LATERAL FLATTEN(input=>unique_commands.split_parts) AS flat
GROUP BY 1, 2
