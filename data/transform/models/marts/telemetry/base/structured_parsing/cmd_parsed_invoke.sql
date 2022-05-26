WITH prep AS (
    SELECT
        unique_commands.command,
        unique_commands.command_category,
        args_parsed.args,
        args_parsed.environment,
        CASE
            WHEN GET(unique_commands.split_parts, 2) NOT LIKE '--%'
                AND (
                    GET(unique_commands.split_parts, 2) LIKE 'tap-%'
                    OR GET(unique_commands.split_parts, 2) LIKE 'tap_%'
                    OR GET(
                        unique_commands.split_parts, 2
                    ) LIKE 'pipelinewise-tap-%'
                    OR GET(unique_commands.split_parts, 2) LIKE 'target-%'
                    OR GET(unique_commands.split_parts, 2) LIKE 'target_%'
                    OR GET(
                        unique_commands.split_parts, 2
                    ) LIKE 'pipelinewise-target-%'
                    OR GET(
                        unique_commands.split_parts, 2
                    ) = 'meltano-map-transformer'
                    OR GET(unique_commands.split_parts, 2) = 'transform-field'
                )
                THEN [GET(unique_commands.split_parts, 2)::STRING]
        END AS singer_plugins,
        GET(unique_commands.split_parts, 2) AS plugin
    FROM {{ ref('unique_commands') }}
    LEFT JOIN
        {{ ref('args_parsed') }} ON
            unique_commands.command = args_parsed.command
    WHERE unique_commands.command_category = 'meltano invoke'
)

SELECT
    command,
    command_category,
    singer_plugins,
    args,
    environment,
    CASE
        WHEN singer_plugins IS NULL AND plugin IS NOT NULL THEN [plugin]
    END AS other_plugins
FROM prep
