{{
    config(
        enabled=true
    )
}}

WITH _cmd_prep AS (
    SELECT
        unique_commands.command,
        unique_commands.command_category,
        flat.value::STRING AS plugin_element,
        flat.index AS plugin_index,
        CASE
            WHEN
                flat.value::STRING LIKE 'tap-%'
                OR flat.value::STRING LIKE 'tap_%'
                OR flat.value::STRING LIKE 'pipelinewise-tap-%'
                THEN flat.index
        END
        AS tap_index,
        CASE
            WHEN
                flat.value::STRING LIKE 'target-%'
                OR flat.value::STRING LIKE 'target_%'
                OR flat.value::STRING LIKE 'pipelinewise-target-%'
                THEN flat.index
        END
        AS target_index
    FROM {{ ref('unique_commands') }},
        LATERAL FLATTEN(input => STRTOK_TO_ARRAY(command, ' ')) AS flat
),

target_pairs AS (
    SELECT
        command,
        command_category,
        plugin_element,
        plugin_index,
        CASE
            WHEN
                tap_index IS NOT NULL THEN LAG(
                    target_index
                ) IGNORE NULLS OVER (
                    PARTITION BY command ORDER BY plugin_index DESC
                )
        END AS target_pair_index
    FROM _cmd_prep
),

_mappers AS (
    SELECT
        target_pairs.command,
        target_pairs.command_category,
        target_pairs.plugin_index
    FROM target_pairs
    INNER JOIN
        target_pairs AS t2 ON
            target_pairs.command
            = t2.command AND target_pairs.plugin_index >
            t2.plugin_index AND target_pairs.plugin_index <
            t2.target_pair_index
),

meltano_run AS (
    SELECT
        _cmd_prep.command,
        _cmd_prep.command_category,
        ARRAY_AGG(
            CASE WHEN
                _cmd_prep.tap_index IS NOT NULL
                OR _cmd_prep.target_index IS NOT NULL
                OR _mappers.plugin_index IS NOT NULL
                THEN _cmd_prep.plugin_element END
        ) WITHIN GROUP (ORDER BY _cmd_prep.plugin_index ASC) AS singer_plugins,
        ARRAY_AGG(
            CASE WHEN _mappers.plugin_index IS NOT NULL
                THEN _cmd_prep.plugin_element END
        ) WITHIN GROUP (
            ORDER BY _cmd_prep.plugin_index ASC
        ) AS singer_mapper_plugins,
        ARRAY_AGG(
            CASE WHEN _cmd_prep.tap_index IS NULL
                AND _cmd_prep.target_index IS NULL
                AND _mappers.plugin_index IS NULL
                AND _cmd_prep.plugin_element NOT LIKE '--environment%'
                THEN _cmd_prep.plugin_element END
        ) WITHIN GROUP (ORDER BY _cmd_prep.plugin_index ASC) AS other_plugins
    FROM _cmd_prep
    LEFT JOIN
        _mappers ON
            _cmd_prep.command = _mappers.command
            AND _cmd_prep.plugin_index = _mappers.plugin_index
    WHERE _cmd_prep.command_category = 'meltano run'
        AND _cmd_prep.plugin_element NOT IN ('meltano', 'run')
    GROUP BY _cmd_prep.command, _cmd_prep.command_category
)

SELECT
    meltano_run.*,
    args_parsed.args AS args,
    args_parsed.environment
FROM meltano_run
LEFT JOIN {{ ref('args_parsed') }} ON meltano_run.command = args_parsed.command
