with source as (

    select * from {{ source('metronome', 'customer') }}
    WHERE environment_type = 'PRODUCTION'

),

renamed as (

    select
        id,
        name,
        ingest_aliases,
        salesforce_account_id,
        billing_provider_type,
        billing_provider_customer_id,
        created_at,
        updated_at,
        archived_at

    from source

)

select * from renamed
