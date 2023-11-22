with source as (

    select * from {{ source('metronome', 'credit_type') }}
    WHERE environment_type = 'PRODUCTION'

),

renamed as (

    select
        id,
        name,
        is_currency,
        updated_at,
        _metronome_metadata_id

    from source

)

select * from renamed
