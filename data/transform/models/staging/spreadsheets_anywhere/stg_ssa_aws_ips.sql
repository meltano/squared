WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                ip_prefix
            ORDER BY _sdc_batched_at DESC
        ) AS row_num
    FROM {{ source('tap_spreadsheets_anywhere', 'aws_ips') }}

),

renamed AS (

    SELECT
        ip_prefix AS ip_address,
        network_border_group,
        region,
        service
    FROM source
    WHERE row_num = 1

)

SELECT
    *
FROM renamed
