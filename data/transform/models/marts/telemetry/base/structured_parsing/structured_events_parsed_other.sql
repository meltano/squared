WITH unique_commands AS (

    SELECT DISTINCT
        command,
        command_category,
        SPLIT(command, ' ') AS split_parts,
        SPLIT_PART(command, ' ', 3) AS split_part_3,
        SPLIT_PART(command, ' ', 4) AS split_part_4
    FROM USERDEV_PREP.PNADOLNY_WORKSPACE.STRUCTURED_EVENTS

),
_args_prep AS (
    select
        command,
        ARRAY_AGG(
            case when value::STRING like '--%' and value::STRING not like '--environment=%' then value::STRING end
        ) as args
    from
    unique_commands, 
        lateral flatten(input=>split_parts) c
    group by 1
),
meltano_add AS (
    select
        unique_commands.command,
        'meltano ' || GET(SPLIT(unique_commands.command, ' '), 1)::string AS command_category,
        unique_commands.split_part_3 AS plugin_type,
        CASE
            WHEN
                unique_commands.split_part_4 LIKE 'tap-%'
                OR unique_commands.split_part_4 LIKE 'tap_%'
                OR unique_commands.split_part_4 LIKE 'pipelinewise-tap-%' THEN [unique_commands.split_part_4] else []
        END AS singer_plugins,
        _args_prep.args AS args,
        [unique_commands.split_part_4] AS plugins,
        SPLIT_PART(SPLIT_PART(unique_commands.command, '--environment=',2), ' ', 1) AS environment
    from unique_commands 
    LEFT JOIN _args_prep on unique_commands.command = _args_prep.command
    where unique_commands.command like 'meltano add %' or unique_commands.command like 'meltano remove %'
),
meltano_schedule AS (
-- TODO add args
    select
        command,
        command_category || ' add' AS command_category,
        get(split_parts, 2)::string AS name,
        case when get(split_parts, 5)::string like '@%' then get(split_parts, 5)::string else 'custom_cron' end AS schedule,
        SPLIT_PART(SPLIT_PART(command, '--transform=',2), ' ', 1) AS transform_option,
        [get(split_parts, 3), get(split_parts, 4)] AS singer_plugins,
        SPLIT_PART(SPLIT_PART(command, '--environment=',2), ' ', 1) AS environment
    from unique_commands
    where command_category = 'meltano schedule'
    -- its a plugin name
    and get(split_parts, 2) not in ('run', 'list', 'add')

    union all

    select
        command,
        command_category || ' ' || get(split_parts, 2) AS command_category,
        get(split_parts, 3)::string AS name,
        case when get(split_parts, 6)::string like '@%' then get(split_parts, 6)::string else 'custom_cron' end AS schedule,
        SPLIT_PART(SPLIT_PART(command, '--transform=',2), ' ', 1) AS transform_option,
        [get(split_parts, 4), get(split_parts, 5)] AS singer_plugins,
        SPLIT_PART(SPLIT_PART(command, '--environment=',2), ' ', 1) AS environment
    from unique_commands
    where command_category = 'meltano schedule'
    -- its a plugin name just offset
    and get(split_parts, 2) in ('add', 'run')

    union all

    select
        command,
        'meltano schedule list' AS command_category,
        null AS name,
        null AS schedule,
        null AS transform_option,
        null AS singer_plugins,
        SPLIT_PART(SPLIT_PART(command, '--environment=',2), ' ', 1) AS environment
    from unique_commands
    where command_category = 'meltano schedule'
    -- null plugins
    and get(split_parts, 2) = 'list'

),
meltano_test AS (
    select
        unique_commands.command,
        unique_commands.command_category,
        case when get(split_parts, 2) not like '--%' then [get(split_parts, 2)::string] else [] end AS plugins,
        _args_prep.args,
        SPLIT_PART(SPLIT_PART(unique_commands.command, '--environment=',2), ' ', 1) AS environment
    from unique_commands
    LEFT JOIN _args_prep on unique_commands.command = _args_prep.command
    where unique_commands.command_category = 'meltano test'
),
meltano_select AS (
    -- TODO how to handle subcommands like list or --all or --list
    select
        unique_commands.command,
        unique_commands.command_category,
        case when get(split_parts, 3)::string not like '--%' and get(split_parts, 3)::string != 'list' then get(split_parts, 3)::string end  as entity,
        case when get(split_parts, 4)::string not like '--%' and get(split_parts, 3)::string != 'list' then get(split_parts, 4)::string end  as attribute,
        case when get(split_parts, 2) not like '--%' then [get(split_parts, 2)::string] else [] end AS plugins,
        _args_prep.args,
        SPLIT_PART(SPLIT_PART(unique_commands.command, '--environment=',2), ' ', 1) AS environment
    from unique_commands
    LEFT JOIN _args_prep on unique_commands.command = _args_prep.command
    where unique_commands.command_category = 'meltano select'

)

-- schedule (done)
-- test (done)
-- add extractors/loaders/transformers/files/orchestrators/utilities/etc. (done)
-- select
-- remove (done)
-- state 


-- features:
-- environments
-- mappers
-- state

-------- native no plugins used
-- config
-- discover
-- environment
-- init
-- install
-- ui
-- user
-- upgrade
-- version
-- ui
