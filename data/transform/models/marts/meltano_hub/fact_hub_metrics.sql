with plugin_use_3m as (

    select
        sum(event_count) as usage,
        count(distinct project_id) as project_count,
        plugin_name
    from {{ ref('cli_plugin_events__unioned') }}
    where plugin_type in ('tap', 'target')
        and event_date >= current_date - interval '3' month
    group by 3

)
select 
    fact_repo_metrics.repo_full_name,
    fact_repo_metrics.created_at_timestamp,
    fact_repo_metrics.last_push_timestamp,
    fact_repo_metrics.last_updated_timestamp,
    -- TODO: cast these in the staging table
    cast(fact_repo_metrics.num_forks as int) as num_forks,
    cast(fact_repo_metrics.num_open_issues as int) as num_open_issues,
    cast(fact_repo_metrics.num_stargazers as int) as num_stargazers,
    cast(fact_repo_metrics.num_watchers as int) as num_watchers,
    coalesce(plugin_use_3m.usage, 0) meltano_executions_3m,
    coalesce(plugin_use_3m.project_count, 0) meltano_projects_count_3m
from {{ source('hub_meltano', 'fact_repo_metrics') }} as fact_repo_metrics
left join plugin_use_3m
    on fact_repo_metrics.connector_name = plugin_use_3m.plugin_name

