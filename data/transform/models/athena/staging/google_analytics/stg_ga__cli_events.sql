WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                ga_date, ga_eventcategory, ga_eventaction, ga_eventlabel
            ORDER BY DATE_PARSE(_sdc_batched_at, '%Y-%m-%d %H:%i:%s.%f') DESC
        ) AS row_num
    FROM {{ source('tap_google_analytics', 'events') }}
    WHERE ga_eventlabel != '(not set)'

),

renamed AS (

    SELECT
        ga_eventcategory AS command_category,
        ga_eventaction AS command,
        ga_eventlabel AS project_id,
        TO_DATE(ga_date, 'yyyymmdd') AS event_date,
        CAST(ga_totalevents AS INT) AS event_count,
        CAST(report_start_date AS DATE) AS report_start_date,
        CAST(report_end_date AS DATE) AS report_end_date
    FROM source
    WHERE row_num = 1

)

SELECT *
FROM renamed
