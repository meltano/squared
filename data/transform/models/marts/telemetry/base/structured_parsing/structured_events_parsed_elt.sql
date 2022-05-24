select
    unique_commands.command,
    unique_commands.command_category,
    case when unique_commands.command like '%--transform run%' OR unique_commands.command like '%--transform only%' then true else false end AS dbt_run,
    [unique_commands.split_part_3, unique_commands.split_part_4]::ARRAY AS singer_plugins,
    args_parsed.args as args,
    args_parsed.environment
from {{ ref('unique_commands') }}
LEFT JOIN {{ ref('args_parsed') }} on unique_commands.command = args_parsed.command
WHERE unique_commands.command_category = 'meltano elt'

