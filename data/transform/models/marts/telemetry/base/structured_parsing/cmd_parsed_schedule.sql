SELECT
    unique_commands.command,
    unique_commands.command_category || ' add' AS command_category,
    GET(unique_commands.split_parts, 2)::STRING AS schedule_name,
    CASE
        WHEN
            GET(
                unique_commands.split_parts, 5
            )::STRING LIKE '@%' THEN GET(unique_commands.split_parts, 5)::STRING
        ELSE 'custom_cron'
    END AS schedule_cron,
    SPLIT_PART(
        SPLIT_PART(unique_commands.command, '--transform=', 2), ' ', 1
    ) AS transform_option,
    [
        GET(unique_commands.split_parts, 3), GET(unique_commands.split_parts, 4)
    ] AS singer_plugins,
    args_parsed.args,
    SPLIT_PART(
        SPLIT_PART(unique_commands.command, '--environment=', 2), ' ', 1
    ) AS environment
FROM {{ ref('unique_commands') }}
LEFT JOIN
    {{ ref('args_parsed') }} ON
    unique_commands.command = args_parsed.command
WHERE
    unique_commands.command_category = 'meltano schedule'
    -- its a plugin name
    AND GET(unique_commands.split_parts, 2) NOT IN ('run', 'list', 'add')

UNION ALL

SELECT
    unique_commands.command,
    unique_commands.command_category || ' ' || GET(
        unique_commands.split_parts, 2
    ) AS command_category,
    GET(unique_commands.split_parts, 3)::STRING AS schedule_name,
    CASE
        WHEN
            GET(
                unique_commands.split_parts, 6
            )::STRING LIKE '@%' THEN GET(unique_commands.split_parts, 6)::STRING
        ELSE 'custom_cron'
    END AS schedule_cron,
    SPLIT_PART(
        SPLIT_PART(unique_commands.command, '--transform=', 2), ' ', 1
    ) AS transform_option,
    [
        GET(unique_commands.split_parts, 4), GET(unique_commands.split_parts, 5)
    ] AS singer_plugins,
    args_parsed.args,
    SPLIT_PART(
        SPLIT_PART(unique_commands.command, '--environment=', 2), ' ', 1
    ) AS environment
FROM {{ ref('unique_commands') }}
LEFT JOIN
    {{ ref('args_parsed') }} ON
    unique_commands.command = args_parsed.command
WHERE
    unique_commands.command_category = 'meltano schedule'
    -- its a plugin name just offset
    AND GET(unique_commands.split_parts, 2) IN ('add', 'run')

UNION ALL

SELECT
    unique_commands.command,
    'meltano schedule list' AS command_category,
    NULL AS schedule_name,
    NULL AS schedule_cron,
    NULL AS transform_option,
    NULL AS singer_plugins,
    args_parsed.args,
    SPLIT_PART(
        SPLIT_PART(unique_commands.command, '--environment=', 2), ' ', 1
    ) AS environment
FROM {{ ref('unique_commands') }}
LEFT JOIN
    {{ ref('args_parsed') }} ON
    unique_commands.command = args_parsed.command
WHERE
    unique_commands.command_category = 'meltano schedule'
    -- null plugins
    AND GET(unique_commands.split_parts, 2) = 'list'
