{{
    config(
        enabled=true
    )
}}
-- command
-- command_category
-- plugin
-- plugin_category
-- [features]
-- [singer plugins]
-- [other_plugins]
-- [features]

-- ELT
-- invoke
-- schedule run
-- other?


WITH _cmd_prep AS (
    select
        unique_commands.command,
        unique_commands.command_category,
        value::STRING AS plugin_element,
        index AS plugin_index,
        CASE
            WHEN
                value::STRING LIKE 'tap-%'
                OR value::STRING LIKE 'tap_%'
                OR value::STRING LIKE 'pipelinewise-tap-%' THEN index
        END
        tap_index,
            CASE
                WHEN
                    value::STRING LIKE 'target-%'
                    OR value::STRING LIKE 'target_%'
                    OR value::STRING LIKE 'pipelinewise-target-%' THEN index
            END
        AS target_index
    FROM {{ ref('unique_commands') }},
        LATERAL FLATTEN(input => STRTOK_TO_ARRAY(command, ' '))
),
target_pairs as (
    select 
        command,
        command_category,
        plugin_element,
        plugin_index,
        case when tap_index is not null then LAG(target_index) ignore nulls OVER (PARTITION BY command ORDER BY plugin_index desc)  end as target_pair_index
    FROM _cmd_prep
),
_mappers as (
    select
            v1.command,
            v1.command_category,
            v1.plugin_index
    from target_pairs as v1
    inner join target_pairs as v2 on v1.command = v2.command and v1.plugin_index > v2.plugin_index and v1.plugin_index < v2.target_pair_index
),
meltano_run AS (
    select
        _cmd_prep.command,
        _cmd_prep.command_category,
        ARRAY_AGG(
            CASE WHEN
            _cmd_prep.tap_index IS NOT NULL
            OR _cmd_prep.target_index IS NOT NULL
            OR _mappers.plugin_index IS NOT NULL
            THEN plugin_element END
        ) within group (order by _cmd_prep.plugin_index asc) AS singer_plugins,
        ARRAY_AGG(
            CASE WHEN _mappers.plugin_index IS NOT NULL
            THEN plugin_element END
        ) within group (order by _cmd_prep.plugin_index asc) AS singer_mapper_plugins,
        ARRAY_AGG(
            CASE WHEN _cmd_prep.tap_index IS NULL
            AND _cmd_prep.target_index IS NULL
            AND _mappers.plugin_index IS NULL
            AND plugin_element NOT LIKE '--environment%'
            THEN plugin_element END
        ) within group (order by _cmd_prep.plugin_index asc) AS other_plugins
    FROM _cmd_prep
    LEFT JOIN _mappers ON _cmd_prep.command = _mappers.command and _cmd_prep.plugin_index = _mappers.plugin_index
    WHERE _cmd_prep.command_category = 'meltano run'
        AND plugin_element not in ('meltano', 'run')
    group by 1,2
)
select
    meltano_run.*,
    args_parsed.args as args,
    args_parsed.environment
from meltano_run
LEFT JOIN {{ ref('args_parsed') }} on meltano_run.command = args_parsed.command
