-- ELT Taps
select
    event_date,
    project_id,
    event_count,
    split_part(command, ' ', 3) plugin_name,
    'tap' as plugin_type,
    command_category
from {{ ref('stg_google_analytics__cli_events') }}
where command_category = 'meltano elt'

union all

-- ELT Targets
select
    event_date,
    project_id,
    event_count,
    split_part(command, ' ', 4),
    'target',
    command_category
from {{ ref('stg_google_analytics__cli_events') }}
where command_category = 'meltano elt'

union all

-- Invoke Taps
select
    event_date,
    project_id,
    event_count,
    split_part(command, ' ', 3),
    'tap',
    command_category
from {{ ref('stg_google_analytics__cli_events') }}
where command_category = 'meltano invoke'
    and split_part(command, ' ', 3) like 'tap%'

union all

-- Invoke Targets
select
    event_date,
    project_id,
    event_count,
    split_part(command, ' ', 3),
    'target',
    command_category
from {{ ref('stg_google_analytics__cli_events') }}
where command_category = 'meltano invoke'
    and split_part(command, ' ', 3) like 'target%'
