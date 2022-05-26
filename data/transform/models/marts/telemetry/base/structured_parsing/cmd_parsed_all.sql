{{
    config(materialized='table')
}}

WITH manually_parsed AS (
    SELECT
        command,
        command_category,
        singer_plugins,
        singer_mapper_plugins,
        other_plugins,
        args,
        environment,
        'plugin' AS command_type
    FROM {{ ref('cmd_parsed_run') }}

    UNION ALL

    SELECT
        command,
        command_category,
        singer_plugins,
        []::ARRAY AS singer_mapper_plugins,
        CASE
            WHEN dbt_run THEN ['dbt']::ARRAY ELSE []::ARRAY
        END AS other_plugins,
        args,
        environment,
        'plugin' AS command_type
    FROM {{ ref('cmd_parsed_elt') }}

    UNION ALL

    SELECT
        command,
        command_category,
        singer_plugins,
        []::ARRAY AS singer_mapper_plugins,
        other_plugins,
        args,
        environment,
        'plugin' AS command_type
    FROM {{ ref('cmd_parsed_invoke') }}

    UNION ALL

    SELECT
        command,
        command_category,
        singer_plugins,
        NULL AS singer_mapper_plugins,
        other_plugins,
        args,
        environment,
        'plugin' AS command_type
    FROM {{ ref('cmd_parsed_add_remove') }}

    UNION ALL

    SELECT
        command,
        command_category,
        singer_plugins,
        NULL AS singer_mapper_plugins,
        CASE
            WHEN
                transform_option IN ('run', 'only') THEN ['dbt']::ARRAY
            ELSE []::ARRAY
        END AS other_plugins,
        args,
        environment,
        'plugin' AS command_type
    FROM {{ ref('cmd_parsed_schedule') }}
    WHERE command_category != 'meltano schedule list'

    UNION ALL

    SELECT
        command,
        command_category,
        singer_plugins,
        NULL AS singer_mapper_plugins,
        CASE
            WHEN
                transform_option IN ('run', 'only') THEN ['dbt']::ARRAY
            ELSE []::ARRAY
        END AS other_plugins,
        args,
        environment,
        'native' AS command_type
    FROM {{ ref('cmd_parsed_schedule') }}
    WHERE command_category = 'meltano schedule list'

    UNION ALL

    SELECT
        command,
        command_category,
        singer_plugins,
        NULL AS singer_mapper_plugins,
        other_plugins AS other_plugins,
        args,
        environment,
        'plugin' AS command_type
    FROM {{ ref('cmd_parsed_test') }}

    UNION ALL

    SELECT
        command,
        command_category,
        singer_plugins AS singer_plugins,
        NULL AS singer_mapper_plugins,
        NULL AS other_plugins,
        args,
        environment,
        'plugin' AS command_type
    FROM {{ ref('cmd_parsed_select') }}
)

SELECT *
FROM manually_parsed

UNION ALL

SELECT
    unique_commands.command,
    unique_commands.command_category,
    NULL AS singer_plugins,
    NULL AS singer_mapper_plugins,
    NULL AS other_plugins,
    args_parsed.args,
    args_parsed.environment,
    'native' AS command_type
FROM {{ ref('unique_commands') }}
LEFT JOIN manually_parsed ON unique_commands.command = manually_parsed.command
LEFT JOIN
    {{ ref('args_parsed') }} ON unique_commands.command = args_parsed.command
WHERE manually_parsed.command IS NULL
