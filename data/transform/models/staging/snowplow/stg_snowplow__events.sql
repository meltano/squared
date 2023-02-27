{{
    config(
        materialized='table'
    )
}}

WITH blended_source AS (

    SELECT *
    FROM {{ ref('stg_snowplow__events_union_all') }}

),

source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                event_id
            ORDER BY event_created_at::TIMESTAMP DESC
        ) AS row_num
    FROM blended_source

),

clean_new_source AS (

    SELECT *
    FROM source
    WHERE row_num = 1

)

SELECT *
FROM clean_new_source
