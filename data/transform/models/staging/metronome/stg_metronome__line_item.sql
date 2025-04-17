with source as (

    select * from {{ source('metronome', 'line_item') }}

),

renamed as (

    select
        id,
        invoice_id,
        credit_type_id,
        credit_type_name,
        name,
        quantity,
        total,
        product_id,
        group_key,
        group_value,
        updated_at

    from source

)

select * from renamed
