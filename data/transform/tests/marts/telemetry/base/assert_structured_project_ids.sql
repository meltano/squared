SELECT project_id
FROM {{ ref('cli_executions_blended') }}
WHERE project_id NOT IN (
    SELECT DISTINCT project_id FROM {{ ref('structured_executions') }}
    UNION
    SELECT DISTINCT project_id FROM {{ ref('unstructured_executions') }}
)
