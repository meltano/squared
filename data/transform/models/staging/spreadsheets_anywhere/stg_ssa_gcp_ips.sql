WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                id
            ORDER BY _sdc_batched_at DESC
        ) AS row_num
    FROM {{ source('tap_spreadsheets_anywhere', 'gcp_ips') }}

),

renamed AS (

    SELECT
        id,
        ipv4,
        ipv6,
        scope,
        service
    FROM source
    WHERE row_num = 1

)

SELECT *
FROM renamed
