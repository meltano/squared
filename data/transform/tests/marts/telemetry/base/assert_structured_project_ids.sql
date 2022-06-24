SELECT project_id
FROM {{ ref('stg_ga__cli_events') }}
WHERE project_id NOT IN (
    SELECT DISTINCT project_id FROM {{ ref('structured_events') }}
    UNION
    SELECT DISTINCT project_id FROM {{ ref('unstructured_executions') }}
)
