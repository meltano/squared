select
    command,
    SPLIT_PART(SPLIT_PART(unique_commands.command, '--environment=',2), ' ', 1) AS environment,
    ARRAY_AGG(
        case when value::STRING like '--%' and value::STRING not like '--environment=%' then value::STRING end
    ) as args
from
    {{ ref('unique_commands') }},
    lateral flatten(input=>unique_commands.split_parts) c
group by 1,2