WITH unique_commands AS (

    SELECT DISTINCT
        command,
        command_category,
        SPLIT_PART(command, ' ', 3) AS split_part_3,
        SPLIT_PART(command, ' ', 4) AS split_part_4
    FROM {{ ref('events_blended') }}

),

exec_event AS (

    SELECT command
    FROM unique_commands
    WHERE
        command_category IN (
            'meltano invoke',
            'meltano elt',
            'meltano ui',
            'meltano test',
            'meltano run',
            'meltano ui'
        )

    UNION ALL

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano schedule'
        AND split_part_3 LIKE 'run%'

),

pipeline_exec_event AS (

    SELECT command
    FROM unique_commands
    WHERE
        command_category IN (
            'meltano invoke',
            'meltano elt',
            'meltano run'
        )

    UNION ALL

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano schedule'
        AND split_part_3 LIKE 'run%'

),

legacy AS (

    SELECT command
    FROM unique_commands
    WHERE
        command_category IN (
            'meltano add transforms',
            'meltano add dashboards',
            'meltano add models'
        )

),

_run_parse AS (
    SELECT
        command,
        MAX(
            CASE
                WHEN
                    value::STRING LIKE 'tap-%'
                    OR value::STRING LIKE 'pipelinewise-tap-%' THEN index
            END
        ) AS tap_index,
        MAX(
            CASE
                WHEN
                    value::STRING LIKE 'target-%'
                    OR value::STRING LIKE 'pipelinewise-target-%' THEN index
            END
        ) AS target_index,
        MAX(
            CASE
                WHEN
                    value::STRING LIKE 'dbt%' THEN index
            END
        ) AS dbt_index,
        MAX(
            CASE
                WHEN
                    value::STRING LIKE 'airflow%' THEN index
            END
        ) AS airflow_index,
        MAX(
            CASE
                WHEN
                    value::STRING LIKE 'dagster%'
                    OR value::STRING LIKE 'dagit%' THEN index
            END
        ) AS dagster_index,
        MAX(
            CASE
                WHEN
                    value::STRING LIKE 'lightdash%' THEN index
            END
        ) AS lightdash_index,
        MAX(
            CASE
                WHEN
                    value::STRING LIKE 'superset%' THEN index
            END
        ) AS superset_index,
        MAX(
            CASE
                WHEN
                    value::STRING LIKE 'sqlfluff%' THEN index
            END
        ) AS sqlfluff_index,
        MAX(
            CASE
                WHEN
                    value::STRING LIKE 'great_expectations%'
                    OR value::STRING LIKE 'great-expectations%' THEN index
            END
        ) AS ge_index
    FROM unique_commands,
        LATERAL FLATTEN(input => STRTOK_TO_ARRAY(command, ' '))
    WHERE command_category = 'meltano run'
    GROUP BY 1
),

-- Plugins
singer AS (

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano elt'

    UNION ALL

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano invoke'
        AND (
            split_part_3 LIKE 'tap%'
            OR split_part_3 LIKE 'pipelinewise-tap-%'
            OR split_part_3 LIKE 'target%'
            OR split_part_3 LIKE 'pipelinewise-target-%'
        )

    UNION ALL

    SELECT command
    FROM unique_commands
    WHERE
        command_category IN (
            'meltano add extractors', 'meltano add loaders', 'meltano select'
        )

    UNION ALL

    SELECT command
    FROM _run_parse
    WHERE target_index IS NOT NULL OR tap_index IS NOT NULL
),

dbt AS (
    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano elt'
        AND command LIKE 'meltano elt% --transform run%'

    UNION ALL

    SELECT command
    FROM unique_commands
    WHERE command LIKE 'meltano invoke dbt%'

    UNION ALL

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano add transformers'
        AND split_part_4 LIKE 'dbt'

    UNION ALL

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano add files'
        AND split_part_4 LIKE 'dbt'

    UNION ALL

    SELECT command
    FROM _run_parse
    WHERE dbt_index IS NOT NULL

),

airflow AS (
    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano invoke'
        AND split_part_3 LIKE 'airflow%'

    UNION ALL

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano schedule'

    UNION ALL

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano add orchestrators'
        AND split_part_4 LIKE 'airflow'

    UNION ALL

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano add files'
        AND split_part_4 LIKE 'airflow'

    UNION ALL

    SELECT command
    FROM _run_parse
    WHERE airflow_index IS NOT NULL

),

dagster AS (

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano invoke'
        AND split_part_3 LIKE 'dagster%'

    UNION ALL

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano add utilities'
        AND split_part_4 LIKE 'dagster%'

    UNION ALL

    SELECT command
    FROM _run_parse
    WHERE dagster_index IS NOT NULL

),

lightdash AS (

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano invoke'
        AND split_part_3 LIKE 'lightdash%'

    UNION ALL

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano add utilities'
        AND split_part_4 LIKE 'lightdash'

    UNION ALL

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano add files'
        AND split_part_4 LIKE 'lightdash'

    UNION ALL

    SELECT command
    FROM _run_parse
    WHERE lightdash_index IS NOT NULL

),

superset AS (

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano invoke'
        AND split_part_3 LIKE 'superset%'

    UNION ALL

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano add files'
        AND split_part_4 LIKE 'superset'

    UNION ALL

    SELECT command
    FROM _run_parse
    WHERE superset_index IS NOT NULL

),

sqlfluff AS (

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano invoke'
        AND split_part_3 LIKE 'sqlfluff%'

    UNION ALL

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano add files'
        AND split_part_4 LIKE 'sqlfluff'

    UNION ALL

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano add utilities'
        AND split_part_4 LIKE 'sqlfluff'

    UNION ALL

    SELECT command
    FROM _run_parse
    WHERE sqlfluff_index IS NOT NULL

),

great_expectations AS (

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano invoke'
        AND (split_part_3 LIKE 'great-expectations%'
            OR split_part_3 LIKE 'great_expectations%')

    UNION ALL

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano add files'
        AND split_part_4 IN ('great-expectations', 'great_expectations')

    UNION ALL

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano add utilities'
        AND split_part_4 IN ('great-expectations', 'great_expectations')

    UNION ALL

    SELECT command
    FROM _run_parse
    WHERE ge_index IS NOT NULL

),

-- Features
environments AS (

    SELECT command
    FROM unique_commands
    WHERE command LIKE '% --environment=%'

),

cli_test AS (

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano test'

),

cli_run AS (

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano run'

),

cli_mappers AS (

    SELECT command
    FROM _run_parse
    -- Commands need at least 3 plugins to be considered.
    WHERE NOT(
            SPLIT_PART(
                command, ' ', 5
            ) = '' OR STARTSWITH(SPLIT_PART(command, ' ', 5), '--environment')
        )
        -- A tap and target combination separated by at least 1 other plugin
        -- is considered a mappers.
        AND target_index - tap_index > 1

)

SELECT
    unique_commands.command,
    unique_commands.command_category,
    NOT COALESCE(exec_event.command IS NULL, FALSE) AS is_exec_event,
    NOT COALESCE(
        pipeline_exec_event.command IS NULL, FALSE
    ) AS is_pipeline_exec_event,
    NOT COALESCE(legacy.command IS NULL, FALSE) AS is_legacy_event,
    NOT COALESCE(singer.command IS NULL, FALSE) AS is_plugin_singer,
    NOT COALESCE(dbt.command IS NULL, FALSE) AS is_plugin_dbt,
    NOT COALESCE(airflow.command IS NULL, FALSE) AS is_plugin_airflow,
    NOT COALESCE(dagster.command IS NULL, FALSE) AS is_plugin_dagster,
    NOT COALESCE(lightdash.command IS NULL, FALSE) AS is_plugin_lightdash,
    NOT COALESCE(superset.command IS NULL, FALSE) AS is_plugin_superset,
    NOT COALESCE(sqlfluff.command IS NULL, FALSE) AS is_plugin_sqlfluff,
    NOT COALESCE(
        great_expectations.command IS NULL, FALSE
    ) AS is_plugin_great_ex,
    NOT COALESCE(
        environments.command IS NULL, FALSE
    ) AS is_os_feature_environments,
    NOT COALESCE(cli_test.command IS NULL, FALSE) AS is_os_feature_test,
    NOT COALESCE(cli_run.command IS NULL, FALSE) AS is_os_feature_run,
    NOT COALESCE(
        cli_mappers.command IS NULL, FALSE
    ) AS is_os_feature_mappers
FROM unique_commands
LEFT JOIN exec_event ON unique_commands.command = exec_event.command
LEFT JOIN
    pipeline_exec_event ON unique_commands.command = pipeline_exec_event.command
LEFT JOIN legacy ON unique_commands.command = legacy.command
LEFT JOIN singer ON unique_commands.command = singer.command
LEFT JOIN dbt ON unique_commands.command = dbt.command
LEFT JOIN airflow ON unique_commands.command = airflow.command
LEFT JOIN dagster ON unique_commands.command = dagster.command
LEFT JOIN lightdash ON unique_commands.command = lightdash.command
LEFT JOIN superset ON unique_commands.command = superset.command
LEFT JOIN sqlfluff ON unique_commands.command = sqlfluff.command
LEFT JOIN
    great_expectations ON unique_commands.command = great_expectations.command
LEFT JOIN environments ON unique_commands.command = environments.command
LEFT JOIN cli_test ON unique_commands.command = cli_test.command
LEFT JOIN cli_run ON unique_commands.command = cli_run.command
LEFT JOIN cli_mappers ON unique_commands.command = cli_mappers.command
