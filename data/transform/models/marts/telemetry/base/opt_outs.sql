{{
    config(materialized='table')
}}

SELECT
    project_uuid AS project_id,
    MIN(event_created_at) AS opted_out_at
FROM {{ ref('unstruct_event_flattened') }}
WHERE event_name = 'telemetry_state_change_event'
    AND setting_name = 'send_anonymous_usage_stats'
    AND changed_to = 'false'
    AND project_uuid IS NOT NULL
GROUP BY 1
