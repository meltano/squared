WITH source AS (

    SELECT
        {{ dbt_utils.surrogate_key(['ga_date', 'ga_eventcategory', 'ga_eventaction', 'ga_eventlabel']) }} AS event_surrogate_key,
        *
    FROM {{ source('tap_google_analytics', 'events') }}

),

clean_source AS (

    SELECT
        *,    
        ROW_NUMBER() OVER (
            PARTITION BY
                event_surrogate_key
            ORDER BY _sdc_batched_at DESC
        ) AS row_num
    FROM source
    WHERE ga_eventlabel != '(not set)'

),

renamed AS (

    SELECT
        event_surrogate_key,
        ga_eventcategory AS command_category,
        ga_eventaction AS command,
        ga_eventlabel AS project_id,
        TO_DATE(ga_date, 'yyyymmdd') AS event_date,
        CAST(ga_totalevents AS INT) AS event_count,
        CAST(report_start_date AS DATE) AS report_start_date,
        CAST(report_end_date AS DATE) AS report_end_date
    FROM clean_source
    WHERE row_num = 1

)

SELECT *
FROM renamed
