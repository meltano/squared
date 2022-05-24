    select
        unique_commands.command,
        unique_commands.command_category || ' add' AS command_category,
        get(unique_commands.split_parts, 2)::string AS name,
        case when get(unique_commands.split_parts, 5)::string like '@%' then get(unique_commands.split_parts, 5)::string else 'custom_cron' end AS schedule,
        SPLIT_PART(SPLIT_PART(unique_commands.command, '--transform=',2), ' ', 1) AS transform_option,
        [get(unique_commands.split_parts, 3), get(unique_commands.split_parts, 4)] AS singer_plugins,
        args_parsed.args,
        SPLIT_PART(SPLIT_PART(unique_commands.command, '--environment=',2), ' ', 1) AS environment
    from {{ ref('unique_commands') }}
    LEFT JOIN {{ ref('args_parsed') }} on unique_commands.command = args_parsed.command
    where unique_commands.command_category = 'meltano schedule'
    -- its a plugin name
    and get(unique_commands.split_parts, 2) not in ('run', 'list', 'add')

    union all

    select
        unique_commands.command,
        unique_commands.command_category || ' ' || get(unique_commands.split_parts, 2) AS command_category,
        get(unique_commands.split_parts, 3)::string AS name,
        case when get(unique_commands.split_parts, 6)::string like '@%' then get(unique_commands.split_parts, 6)::string else 'custom_cron' end AS schedule,
        SPLIT_PART(SPLIT_PART(unique_commands.command, '--transform=',2), ' ', 1) AS transform_option,
        [get(unique_commands.split_parts, 4), get(unique_commands.split_parts, 5)] AS singer_plugins,
        args_parsed.args,
        SPLIT_PART(SPLIT_PART(unique_commands.command, '--environment=',2), ' ', 1) AS environment
    from {{ ref('unique_commands') }}
    LEFT JOIN {{ ref('args_parsed') }} on unique_commands.command = args_parsed.command
    where unique_commands.command_category = 'meltano schedule'
    -- its a plugin name just offset
    and get(unique_commands.split_parts, 2) in ('add', 'run')

    union all

    select
        unique_commands.command,
        'meltano schedule list' AS command_category,
        null AS name,
        null AS schedule,
        null AS transform_option,
        null AS singer_plugins,
        args_parsed.args,
        SPLIT_PART(SPLIT_PART(unique_commands.command, '--environment=',2), ' ', 1) AS environment
    from {{ ref('unique_commands') }}
    LEFT JOIN {{ ref('args_parsed') }} on unique_commands.command = args_parsed.command
    where unique_commands.command_category = 'meltano schedule'
    -- null plugins
    and get(unique_commands.split_parts, 2) = 'list'