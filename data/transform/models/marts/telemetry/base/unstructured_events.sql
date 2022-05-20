{{
    config(
        enabled=false
    )
}}

SELECT
    'snowplow' AS event_source,
    'unstructured' AS event_type,
    stg_snowplow__events.contexts,
    stg_snowplow__events.derived_contexts,
    stg_snowplow__events.event_id,
    stg_snowplow__events.event_created_at,
    stg_snowplow__events.event_created_date
FROM {{ ref('stg_snowplow__events') }}
INNER JOIN
    {{ ref('event_src_activation') }} ON
        stg_snowplow__events.se_label = event_src_activation.project_id
WHERE
    stg_snowplow__events.event_created_date >= event_src_activation.sp_activate_date
