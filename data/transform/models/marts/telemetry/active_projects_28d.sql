{{
    config(materialized='table')
}}

with exec_projects as (
    SELECT
        project_id,
        SUM(CASE WHEN command_category in ('meltano elt', 'meltano invoke') THEN event_count ELSE 0 END) AS exec_count
    FROM {{ ref('fact_cli_events') }}
    GROUP BY project_id
)
select
    event_date,
    (
        select
            count(distinct project_id)
        from (

            select
                distinct event_date, project_id
            from {{ ref('stg_ga__cli_events') }}
        ) as d2
        where
            d2.event_date between dateadd(day,-28,d.event_date) and d.event_date
    ) as count_all,
    (
        select
            count(distinct project_id)
        from (
            select distinct stg_ga__cli_events.event_date, stg_ga__cli_events.project_id
            from {{ ref('stg_ga__cli_events') }}
            LEFT JOIN exec_projects ON stg_ga__cli_events.project_id = exec_projects.project_id
            WHERE exec_projects.exec_count > 1
        ) as d2
        where
            d2.event_date between dateadd(day,-28,d.event_date) and d.event_date
    ) as count_elt_invoke_lifetime_greater_1,
    (
        select
            count(distinct project_id)
        from (
            select distinct stg_ga__cli_events.event_date, stg_ga__cli_events.project_id
            from {{ ref('stg_ga__cli_events') }}
            LEFT JOIN exec_projects ON stg_ga__cli_events.project_id = exec_projects.project_id
            WHERE exec_projects.exec_count > 0
        ) as d2
        where
            d2.event_date between dateadd(day,-28,d.event_date) and d.event_date
    ) as count_elt_invoke_lifetime_greater_0,
    (
        select
            count(distinct project_id)
        from 
        (
            select
                stg_ga__cli_events.event_date,
                stg_ga__cli_events.project_id,
                SUM(CASE WHEN command_category in ('meltano elt', 'meltano invoke') THEN event_count ELSE 0 END) AS exec_count
            from {{ ref('stg_ga__cli_events') }}
            group by 1, 2
        ) as d2
        where
            d2.event_date between dateadd(day,-28,d.event_date) and d.event_date
            and d2.exec_count > 1
    ) as count_elt_invoke_greater_1_per_month,
    (
        select
            count(distinct project_id)
        from 
        (
            select
                stg_ga__cli_events.event_date,
                stg_ga__cli_events.project_id,
                SUM(CASE WHEN command_category in ('meltano elt', 'meltano invoke') THEN event_count ELSE 0 END) AS exec_count
            from {{ ref('stg_ga__cli_events') }}
            group by 1, 2
        ) as d2
        where
            d2.event_date between dateadd(day,-28,d.event_date) and d.event_date
            and d2.exec_count > 0
    ) as count_elt_invoke_greater_0_per_month
from (
    select distinct event_date from {{ ref('stg_ga__cli_events') }}
) as d
