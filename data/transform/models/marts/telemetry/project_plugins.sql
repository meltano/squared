with base_week as (
    select
        count(distinct plugin_category) as plugin_cnt,
        project_id,
        date_trunc('week', event_ts) as week_date
    from {{ ref('fact_plugin_usage') }}
    group by 2,3
),
base_month as (
    select
        count(distinct plugin_category) as plugin_cnt,
        project_id,
        date_trunc('month', event_ts) as month_date
    from {{ ref('fact_plugin_usage') }}
    group by 2,3
)
select
    count(project_id) as total_projects,
    sum(plugin_cnt) as plugin_score,
    avg(plugin_cnt) as avg_plugin_per_proj,
    week_date as agg_period_date,
    'week' AS agg_period
from base_week
group by 4,5

union all

select
    count(project_id) as total_projects,
    sum(plugin_cnt) as plugin_score,
    avg(plugin_cnt) as avg_plugin_per_proj,
    month_date as agg_period_date,
    'month' AS agg_period
from base_month
group by 4,5
