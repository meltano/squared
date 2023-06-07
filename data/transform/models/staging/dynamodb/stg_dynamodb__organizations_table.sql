WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY tenant_resource_key
            ORDER BY _sdc_batched_at::TIMESTAMP_NTZ DESC
        ) AS row_num
    FROM {{ source('tap_dynamodb', 'organizations_table') }}
),

renamed AS (

    SELECT
        org_name,
        display_name AS org_display_name,
        tenant_resource_key
    FROM source
    WHERE row_num = 1

)

SELECT *
FROM renamed
