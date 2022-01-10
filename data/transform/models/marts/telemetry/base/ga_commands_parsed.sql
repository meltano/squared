WITH unique_commands AS (

    SELECT DISTINCT
        command,
        command_category
    FROM {{ ref('stg_ga__cli_events') }}

),

exec_event AS (

    SELECT command
    FROM unique_commands
    WHERE
        command_category IN (
            'meltano invoke', 'meltano elt', 'meltano ui', 'meltano test'
        )

    UNION DISTINCT

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano schedule'
        AND SPLIT_PART(command, ' ', 3) LIKE 'run%'

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

-- Plugins
singer AS (

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano elt'

    UNION DISTINCT

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano invoke'
        AND (
            SPLIT_PART(command, ' ', 3) LIKE 'tap%'
            OR SPLIT_PART(command, ' ', 3) LIKE 'target%'
        )

    UNION DISTINCT

    SELECT command
    FROM unique_commands
    WHERE
        command_category IN (
            'meltano add extractors', 'meltano add loaders', 'meltano select'
        )
),

dbt AS (
    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano elt'
        AND command LIKE 'meltano elt% --transform run%'

    UNION DISTINCT

    SELECT command
    FROM unique_commands
    WHERE command LIKE 'meltano invoke dbt%'

    UNION DISTINCT

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano add transformers'
        AND SPLIT_PART(command, ' ', 4) LIKE 'dbt'

    UNION DISTINCT

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano add files'
        AND SPLIT_PART(command, ' ', 4) LIKE 'dbt'

),

airflow AS (
    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano invoke'
        AND SPLIT_PART(command, ' ', 3) LIKE 'airflow%'

    UNION DISTINCT

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano schedule'

    UNION DISTINCT

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano add orchestrators'
        AND SPLIT_PART(command, ' ', 4) LIKE 'airflow'

    UNION DISTINCT

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano add files'
        AND SPLIT_PART(command, ' ', 4) LIKE 'airflow'

),

dagster AS (

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano invoke'
        AND SPLIT_PART(command, ' ', 3) LIKE 'dagster'

    UNION DISTINCT

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano add utilities'
        AND SPLIT_PART(command, ' ', 4) LIKE 'dagster'

),

lightdash AS (

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano invoke'
        AND SPLIT_PART(command, ' ', 3) LIKE 'lighdash'

    UNION DISTINCT

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano add utilities'
        AND SPLIT_PART(command, ' ', 4) LIKE 'lighdash'

    UNION DISTINCT

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano add files'
        AND SPLIT_PART(command, ' ', 4) LIKE 'lighdash'

),

superset AS (

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano invoke'
        AND SPLIT_PART(command, ' ', 3) LIKE 'superset'

    UNION DISTINCT

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano add files'
        AND SPLIT_PART(command, ' ', 4) LIKE 'superset'

),

sqlfluff AS (

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano invoke'
        AND SPLIT_PART(command, ' ', 3) LIKE 'sqlfluff'

    UNION DISTINCT

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano add files'
        AND SPLIT_PART(command, ' ', 4) LIKE 'sqlfluff'

    UNION DISTINCT

    SELECT command
    FROM unique_commands
    WHERE command_category = 'meltano add utilities'
        AND SPLIT_PART(command, ' ', 4) LIKE 'sqlfluff'
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

)

SELECT
    unique_commands.command,
    unique_commands.command_category,
    NOT COALESCE(exec_event.command IS NULL, FALSE) AS is_exec_event,
    NOT COALESCE(legacy.command IS NULL, FALSE) AS is_legacy_event,
    NOT COALESCE(singer.command IS NULL, FALSE) AS is_plugin_singer,
    NOT COALESCE(dbt.command IS NULL, FALSE) AS is_plugin_dbt,
    NOT COALESCE(airflow.command IS NULL, FALSE) AS is_plugin_airflow,
    NOT COALESCE(dagster.command IS NULL, FALSE) AS is_plugin_dagster,
    NOT COALESCE(lightdash.command IS NULL, FALSE) AS is_plugin_lightdash,
    NOT COALESCE(superset.command IS NULL, FALSE) AS is_plugin_superset,
    NOT COALESCE(sqlfluff.command IS NULL, FALSE) AS is_plugin_sqlfluff,
    NOT COALESCE(
        environments.command IS NULL, FALSE
    ) AS is_os_feature_environments,
    NOT COALESCE(cli_test.command IS NULL, FALSE) AS is_os_feature_test,
    NOT COALESCE(cli_run.command IS NULL, FALSE) AS is_os_feature_run
FROM unique_commands
LEFT JOIN exec_event ON unique_commands.command = exec_event.command
LEFT JOIN legacy ON unique_commands.command = legacy.command
LEFT JOIN singer ON unique_commands.command = singer.command
LEFT JOIN dbt ON unique_commands.command = dbt.command
LEFT JOIN airflow ON unique_commands.command = airflow.command
LEFT JOIN dagster ON unique_commands.command = dagster.command
LEFT JOIN lightdash ON unique_commands.command = lightdash.command
LEFT JOIN superset ON unique_commands.command = superset.command
LEFT JOIN sqlfluff ON unique_commands.command = sqlfluff.command
LEFT JOIN environments ON unique_commands.command = environments.command
LEFT JOIN cli_test ON unique_commands.command = cli_test.command
LEFT JOIN cli_run ON unique_commands.command = cli_run.command
