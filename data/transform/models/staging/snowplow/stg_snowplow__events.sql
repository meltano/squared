{{
    config(
        materialized='table'
    )
}}

WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                event_id
            ORDER BY event_created_at::TIMESTAMP DESC
        ) AS dedupe_rank
    FROM {{ ref('stg_snowplow__events_union_all') }}

)

SELECT *
FROM source
WHERE dedupe_rank = 1
