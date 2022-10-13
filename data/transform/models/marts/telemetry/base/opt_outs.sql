{{
    config(materialized='table')
}}

SELECT
    context_project.project_uuid AS project_id,
    MIN(stg_snowplow__events.event_created_at) AS opted_out_at
FROM {{ ref('event_telemetry_state_change') }}
LEFT JOIN {{ ref('stg_snowplow__events') }}
    ON event_telemetry_state_change.event_id = stg_snowplow__events.event_id
LEFT JOIN {{ ref('context_project') }}
    ON event_telemetry_state_change.event_id = context_project.event_id
LEFT JOIN {{ ref('context_environment') }}
    ON event_telemetry_state_change.event_id = context_environment.event_id
WHERE event_telemetry_state_change.setting_name = 'send_anonymous_usage_stats'
    AND event_telemetry_state_change.changed_to = 'false'
    AND context_project.project_uuid IS NOT NULL
GROUP BY 1
