SELECT
    plugin_executions.*,
    project_dim.first_event_at AS project_created_at,
    project_dim.is_active AS project_is_active,
    ip_address_dim.cloud_provider,
    ip_address_dim.execution_location
FROM {{ ref('plugin_executions') }}
LEFT JOIN {{ ref('project_dim') }}
    ON plugin_executions.project_id = project_dim.project_id
LEFT JOIN {{ ref('ip_address_dim') }}
    ON plugin_executions.ip_address_hash = ip_address_dim.ip_address_hash
