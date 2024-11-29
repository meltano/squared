with source as (

    select * from {{ source('metronome', 'credit_grant_deduction') }}

),

renamed as (

    select
        id,
        credit_grant_id,
        amount,
        memo,
        invoice_id,
        effective_at,
        updated_at

    from source

)

select * from renamed
