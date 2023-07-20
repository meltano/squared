with source as (

    select * from {{ source('metronome', 'credit_grant') }}
    WHERE environment_type = 'PRODUCTION'

),

renamed as (

    select
        id,
        customer_id,
        name,
        invoice_id,
        priority,
        reason,
        amount_granted,
        amount_granted_credit_type_id,
        amount_paid,
        amount_paid_credit_type_id,
        product_ids,
        created_at,
        updated_at,
        effective_at,
        expires_at,
        voided_at

    from source

)

select * from renamed
