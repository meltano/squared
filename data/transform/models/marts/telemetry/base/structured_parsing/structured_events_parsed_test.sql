
with prep as (
    select
        unique_commands.command,
        unique_commands.command_category,
        CASE
            WHEN get(split_parts, 2) not like '--%'
            and (
                get(split_parts, 2) LIKE 'tap-%'
                OR get(split_parts, 2) LIKE 'tap_%'
                OR get(split_parts, 2) LIKE 'pipelinewise-tap-%'
                OR get(split_parts, 2) LIKE 'target-%'
                OR get(split_parts, 2) LIKE 'target_%'
                OR get(split_parts, 2) LIKE 'pipelinewise-target-%'
                OR get(split_parts, 2) = 'meltano-map-transformer'
                OR get(split_parts, 2) = 'transform-field'
            )
        THEN [get(split_parts, 2)::string] end AS singer_plugins,
        args_parsed.args,
        args_parsed.environment,
        CASE WHEN get(split_parts, 2) not like '--%' THEN get(split_parts, 2) END as plugin
    from {{ ref('unique_commands') }}
    LEFT JOIN {{ ref('args_parsed') }} on unique_commands.command = args_parsed.command
    where unique_commands.command_category = 'meltano test'
)
SELECT
    command,
    command_category,
    singer_plugins,
    CASE WHEN singer_plugins IS NULL AND plugin IS NOT NULL THEN [plugin] END AS other_plugins,
    args,
    environment
FROM prep