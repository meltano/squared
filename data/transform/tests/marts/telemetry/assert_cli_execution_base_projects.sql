SELECT COUNT(*)
FROM {{ ref('cli_executions_base') }}
LEFT JOIN
    {{ ref('project_dim') }} ON
        cli_executions_base.project_id = project_dim.project_id
WHERE project_dim.project_id IS NULL
