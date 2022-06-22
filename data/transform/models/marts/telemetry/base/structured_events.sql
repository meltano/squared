{{
    config(materialized='table')
}}

SELECT
    'snowplow' AS event_source,
    'structured' AS event_type,
    stg_snowplow__events.derived_contexts,
    contexts,
    1 AS event_count,
    stg_snowplow__events.se_category AS command_category,
    stg_snowplow__events.se_action AS command,
    stg_snowplow__events.se_label AS project_id,
    stg_snowplow__events.event_id,
    stg_snowplow__events.event_created_at,
    stg_snowplow__events.event_created_date
FROM {{ ref('stg_snowplow__events') }}
INNER JOIN
    {{ ref('event_src_activation') }} ON
        stg_snowplow__events.se_label = event_src_activation.project_id
WHERE
    stg_snowplow__events.event_created_date
    >= event_src_activation.sp_activate_date

UNION

SELECT
    'ga' AS event_source,
    'structured' AS event_type,
    NULL AS derived_contexts,
    NULL AS contexts,
    stg_ga__cli_events.event_count,
    stg_ga__cli_events.command_category,
    stg_ga__cli_events.command,
    stg_ga__cli_events.project_id,
    stg_ga__cli_events.event_surrogate_key AS event_id,
    stg_ga__cli_events.event_date AS event_created_at,
    stg_ga__cli_events.event_date AS event_created_date
FROM {{ ref('stg_ga__cli_events') }}
LEFT JOIN
    {{ ref('event_src_activation') }} ON
        stg_ga__cli_events.project_id = event_src_activation.project_id
WHERE
    event_src_activation.sp_activate_date IS NULL
    OR stg_ga__cli_events.event_date < event_src_activation.sp_activate_date
