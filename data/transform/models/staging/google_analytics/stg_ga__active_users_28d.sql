WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                ga_date
            ORDER BY DATE_PARSE(_sdc_batched_at, '%Y-%m-%d %H:%i:%s.%f') DESC
        ) AS row_num
    FROM {{ source('tap_google_analytics', 'active_users_28d') }}

),

renamed AS (

    SELECT
        TO_DATE(ga_date, 'yyyymmdd') AS ga_date,
        ga_28dayusers as active_user_count_28d,
        CAST(report_start_date AS DATE) AS report_start_date,
        CAST(report_end_date AS DATE) AS report_end_date
    FROM source
    WHERE row_num = 1

)

SELECT *
FROM renamed
