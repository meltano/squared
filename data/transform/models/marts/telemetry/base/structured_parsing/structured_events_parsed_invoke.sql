WITH unique_commands AS (

    SELECT DISTINCT
        command,
        command_category,
        SPLIT_PART(command, ' ', 3) AS split_part_3,
        SPLIT_PART(command, ' ', 4) AS split_part_4
    FROM USERDEV_PREP.PNADOLNY_WORKSPACE.STRUCTURED_EVENTS
),
_cmd_prep AS (
    select
        unique_commands.command,
        unique_commands.command_category,
        value::STRING AS plugin_element,
        index AS plugin_index,
        split_part_3,
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
    FROM unique_commands,
        LATERAL FLATTEN(input => STRTOK_TO_ARRAY(command, ' '))
),
meltano_invoke AS (
select
    _cmd_prep.command,
    _cmd_prep.command_category,
    ARRAY_AGG(
        CASE WHEN
        _cmd_prep.tap_index IS NOT NULL
        OR _cmd_prep.target_index IS NOT NULL
        THEN plugin_element END
    ) within group (order by _cmd_prep.plugin_index asc) AS singer_plugins,
    ARRAY_AGG(
        CASE WHEN _cmd_prep.plugin_index = 2
            AND _cmd_prep.tap_index IS NULL
            AND _cmd_prep.target_index IS NULL
        THEN plugin_element END
    ) AS other_plugins,
    MAX(
        CASE
            WHEN
                plugin_element LIKE '--environment%' THEN SPLIT_PART(plugin_element, '=',2)
        END
    ) AS environment,
    ARRAY_AGG(
        CASE WHEN _cmd_prep.tap_index IS NULL
            AND _cmd_prep.target_index IS NULL AND _cmd_prep.plugin_index > 2 AND plugin_element NOT LIKE '--environment%'
        THEN plugin_element END
    ) within group (order by _cmd_prep.plugin_index asc) AS args
FROM _cmd_prep
WHERE _cmd_prep.command_category = 'meltano invoke'
AND plugin_element not in ('meltano', 'invoke')
group by 1,2
)
select * from meltano_invoke