select
    max(event_date) as updated_at,
    'meltano_metrics' as metric_type
from {{ ref('cli_plugin_events__unioned') }}

union all

select
    -- TODO: cast to timestamp in stage model
    max(date_parse(batch_timestamp, '%Y-%m-%d %H:%i:%s.%f')),
    'github_metrics'
from {{ source('hub_meltano', 'fact_repo_metrics') }}
