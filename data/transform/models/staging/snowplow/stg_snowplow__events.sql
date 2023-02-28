{{
    # TODO: Debug performance. As of Feb 28, build time is approximately 40 minutes
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
    -- {% if is_incremental() %}
    -- -- TODO: Is this safe or would we lose records?:
    -- WHERE uploaded_at >= (SELECT max(UPLOADED_AT) FROM {{ this }})
    -- {% endif %}

SELECT *
FROM source
WHERE dedupe_rank = 1
