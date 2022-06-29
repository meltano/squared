SELECT project_id
FROM {{ ref('stg_ga__cli_events') }}
WHERE project_id NOT IN (
    SELECT DISTINCT project_id FROM {{ ref('cli_executions') }}
)
