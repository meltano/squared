with prep as (
    select
        unique_commands.command,
        'meltano ' || GET(SPLIT(unique_commands.command, ' '), 1)::string AS command_category,
        get(split_parts, 2)::string AS plugin_type,
        CASE
            WHEN get(split_parts, 2)::string in ('extractors', 'extractor', 'loaders', 'loader', 'mappers', 'mapper')
            OR 
            (
                get(split_parts, 3) not like '--%'
                and (
                    get(split_parts, 3) LIKE 'tap-%'
                    OR get(split_parts, 3) LIKE 'tap_%'
                    OR get(split_parts, 3) LIKE 'pipelinewise-tap-%'
                    OR get(split_parts, 3) LIKE 'target-%'
                    OR get(split_parts, 3) LIKE 'target_%'
                    OR get(split_parts, 3) LIKE 'pipelinewise-target-%'
                    OR get(split_parts, 3) = 'meltano-map-transformer'
                    OR get(split_parts, 3) = 'transform-field'
                )
            )
        THEN [get(split_parts, 3)::string] end AS singer_plugins,
        args_parsed.args,
        args_parsed.environment,
        get(split_parts, 3) as plugin
    from {{ ref('unique_commands') }}
    LEFT JOIN {{ ref('args_parsed') }} on unique_commands.command = args_parsed.command
    where unique_commands.command_category like 'meltano add %' or unique_commands.command like 'meltano remove %'
)
SELECT
    command,
    command_category,
    plugin_type,
    singer_plugins,
    CASE WHEN singer_plugins IS NULL AND plugin IS NOT NULL THEN [plugin] END AS other_plugins,
    args,
    environment
FROM prep
