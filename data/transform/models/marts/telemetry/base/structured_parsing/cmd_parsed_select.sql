SELECT
    unique_commands.command,
    unique_commands.command_category,
    args_parsed.args,
    CASE
        WHEN
            GET(
                unique_commands.split_parts, 3
            )::STRING NOT LIKE '--%'
            THEN GET(unique_commands.split_parts, 3)::STRING
    END AS entity,
    CASE
        WHEN
            GET(
                unique_commands.split_parts, 4
            )::STRING NOT LIKE '--%'
            THEN GET(unique_commands.split_parts, 4)::STRING
    END AS attribute,
    CASE
        WHEN
            GET(
                unique_commands.split_parts, 2
            ) NOT LIKE '--%' THEN [GET(unique_commands.split_parts, 2)::STRING]
        ELSE []
    END AS singer_plugins,
    SPLIT_PART(
        SPLIT_PART(unique_commands.command, '--environment=', 2), ' ', 1
    ) AS environment
FROM {{ ref('unique_commands') }}
LEFT JOIN
    {{ ref('args_parsed') }} ON unique_commands.command = args_parsed.command
WHERE unique_commands.command_category = 'meltano select'
