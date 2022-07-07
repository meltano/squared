SELECT
    plugin_executions.*,
    project_dim.first_event_at AS project_created_at,
    project_dim.is_active AS project_is_active
FROM {{ ref('plugin_executions') }}
LEFT JOIN {{ ref('project_dim') }}
