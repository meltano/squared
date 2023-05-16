WITH prep AS (
    SELECT
        unique_commands.command,
        args_parsed.args,
        args_parsed.environment,
        GET(unique_commands.split_parts, 2)::STRING AS plugin_type,
        'meltano ' || GET(
            SPLIT(unique_commands.command, ' '), 1
        )::STRING AS command_category,
        CASE
            WHEN
                GET(
                    unique_commands.split_parts, 2
                )::STRING IN (
                    'extractors',
                    'extractor',
                    'loaders',
                    'loader',
                    'mappers',
                    'mapper'
                )
                OR (
                    GET(unique_commands.split_parts, 3) NOT LIKE '--%'
                    AND (
                        GET(
                            unique_commands.split_parts, 3
                        ) LIKE 'tap-%'
                        OR GET(
                            unique_commands.split_parts, 3
                        ) LIKE 'tap_%'
                        OR GET(
                            unique_commands.split_parts, 3
                        ) LIKE 'pipelinewise-tap-%'
                        OR GET(
                            unique_commands.split_parts, 3
                        ) LIKE 'target-%'
                        OR GET(
                            unique_commands.split_parts, 3
                        ) LIKE 'target_%'
                        OR GET(
                            unique_commands.split_parts, 3
                        ) LIKE 'pipelinewise-target-%'
                        OR GET(
                            unique_commands.split_parts, 3
                        ) = 'meltano-map-transformer'
                        OR GET(
                            unique_commands.split_parts, 3
                        ) = 'transform-field'
                    )
                )
                THEN
                    [
                        GET(unique_commands.split_parts, 3)::STRING
                    ]
        END AS singer_plugins,
        GET(unique_commands.split_parts, 3) AS plugin
    FROM {{ ref('unique_commands') }}
    LEFT JOIN
        {{ ref('args_parsed') }} ON
        unique_commands.command = args_parsed.command
    WHERE
        unique_commands.command_category LIKE 'meltano add %'
        OR unique_commands.command LIKE 'meltano remove %'
)

SELECT
    command,
    command_category,
    plugin_type,
    singer_plugins,
    args,
    environment,
    CASE
        WHEN singer_plugins IS NULL AND plugin IS NOT NULL THEN [plugin]
    END AS other_plugins
FROM prep
