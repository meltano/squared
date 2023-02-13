SELECT
    unique_commands.command,
    unique_commands.command_category,
    args_parsed.args AS args,
    args_parsed.environment,
    [
        unique_commands.split_part_3, unique_commands.split_part_4
    ]::ARRAY AS singer_plugins,
    COALESCE(
        unique_commands.command LIKE '%--transform run%'
        OR unique_commands.command LIKE '%--transform only%',
        FALSE) AS dbt_run
FROM {{ ref('unique_commands') }}
LEFT JOIN
    {{ ref('args_parsed') }} ON unique_commands.command = args_parsed.command
WHERE unique_commands.command_category = 'meltano elt'
