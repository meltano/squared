with source as (
    
    select
        *,
        row_number() over (partition by ga_date, ga_eventcategory, ga_eventaction, ga_eventlabel order by date_parse(_sdc_batched_at, '%Y-%m-%d %H:%i:%s.%f') desc) as row_num
    from {{ source('tap_google_analytics', 'events') }}

),

renamed as (
    
    select
        to_date(ga_date,'yyyymmdd') as event_date,
        ga_eventcategory as command_category,
        ga_eventaction as command,
        ga_eventlabel as project_id,
        cast(ga_totalevents as int) as event_count,
        cast(report_start_date as date) as report_start_date,
        cast(report_end_date as date) as report_end_date
    from source
    where row_num = 1

)

select * from renamed
