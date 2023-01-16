WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY ptr
            ORDER BY _sdc_batched_at DESC
        ) AS row_num
    FROM {{ source('tap_cloudwatch', 'log') }}
),

renamed AS (

    SELECT
        ptr AS log_id,
        timestamp AS created_at_ts,
        message AS log_message
    FROM source
    WHERE row_num = 1

)

SELECT *
FROM renamed
