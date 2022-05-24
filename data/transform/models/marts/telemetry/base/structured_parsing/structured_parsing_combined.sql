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
    FROM {{ ref('structured_events_parsed_run') }}

    union all

    SELECT
        command,
        command_category,
        singer_plugins,
        []::ARRAY AS singer_mapper_plugins,
        case when dbt_run then ['dbt']::ARRAY else []::ARRAY end AS other_plugins,
        args,
        environment,
        'plugin' AS command_type
    FROM {{ ref('structured_events_parsed_elt') }}

    union all

    SELECT
        command,
        command_category,
        singer_plugins,
        []::ARRAY AS singer_mapper_plugins,
        other_plugins,
        args,
        environment,
        'plugin' AS command_type
    FROM {{ ref('structured_events_parsed_invoke') }}

    union all

    SELECT
        command,
        command_category,
        singer_plugins,
        NULL AS singer_mapper_plugins,
        other_plugins,
        args,
        environment,
        'plugin' AS command_type
    FROM {{ ref('structured_events_parsed_add_remove') }}

    union all

    SELECT
        command,
        command_category,
        singer_plugins,
        NULL AS singer_mapper_plugins,
        case when transform_option in ('run', 'only') then ['dbt']::ARRAY else []::ARRAY end AS other_plugins,
        args,
        environment,
        'plugin' AS command_type
    FROM {{ ref('structured_events_parsed_schedule') }}
    WHERE command_category != 'meltano schedule list'

    union all

    SELECT
        command,
        command_category,
        singer_plugins,
        NULL AS singer_mapper_plugins,
        case when transform_option in ('run', 'only') then ['dbt']::ARRAY else []::ARRAY end AS other_plugins,
        args,
        environment,
        'native' AS command_type
    FROM {{ ref('structured_events_parsed_schedule') }}
    WHERE command_category = 'meltano schedule list'

    union all

    SELECT
        command,
        command_category,
        singer_plugins,
        NULL AS singer_mapper_plugins,
        other_plugins AS other_plugins,
        args,
        environment,
        'plugin' AS command_type
    FROM {{ ref('structured_events_parsed_test') }}

    union all

    SELECT
        command,
        command_category,
        singer_plugins AS singer_plugins,
        NULL AS singer_mapper_plugins,
        NULL AS other_plugins,
        args,
        environment,
        'plugin' AS command_type
    FROM {{ ref('structured_events_parsed_select') }}
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
LEFT JOIN {{ ref('args_parsed') }} on unique_commands.command = args_parsed.command
where manually_parsed.command IS NULL