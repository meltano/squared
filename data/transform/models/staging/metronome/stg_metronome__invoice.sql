with source as (

    select * from {{ source('metronome', 'invoice') }}
    WHERE environment_type = 'PRODUCTION'

),

renamed as (

    select
        id,
        status,
        total,
        credit_type_id,
        credit_type_name,
        customer_id,
        plan_id,
        plan_name,
        start_timestamp,
        end_timestamp,
        billing_provider_invoice_id,
        billing_provider_invoice_created_at,
        updated_at

    from source

)

select * from renamed
