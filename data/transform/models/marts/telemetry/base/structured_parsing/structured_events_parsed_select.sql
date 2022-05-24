select
    unique_commands.command,
    unique_commands.command_category,
    case when get(split_parts, 3)::string not like '--%' then get(split_parts, 3)::string end  as entity,
    case when get(split_parts, 4)::string not like '--%' then get(split_parts, 4)::string end  as attribute,
    case when get(split_parts, 2) not like '--%' then [get(split_parts, 2)::string] else [] end AS singer_plugins,
    args_parsed.args,
    SPLIT_PART(SPLIT_PART(unique_commands.command, '--environment=',2), ' ', 1) AS environment
from {{ ref('unique_commands') }}
LEFT JOIN {{ ref('args_parsed') }} on unique_commands.command = args_parsed.command
where unique_commands.command_category = 'meltano select'