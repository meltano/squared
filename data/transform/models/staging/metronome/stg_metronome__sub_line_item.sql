with source as (

    select * from {{ source('metronome', 'sub_line_item') }}

),

renamed as (

    select
        id,
        line_item_id,
        name,
        quantity,
        subtotal,
        charge_id,
        billable_metric_id,
        billable_metric_name,
        tiers,
        updated_at

    from source

)

select * from renamed
