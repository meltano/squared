with source as (

    select * from {{ source('metronome', 'plan_charge') }}
    WHERE environment_type = 'PRODUCTION'

),

renamed as (

    select
        id,
        charge_id,
        charge_name,
        plan_id,
        product_id,
        product_name,
        billable_metric_id,
        billable_metric_name,
        start_period,
        credit_type_id,
        credit_type_name,
        charge_type,
        quantity,
        prices,
        updated_at

    from source

)

select * from renamed