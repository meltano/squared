{{
    config(materialized='table')
}}

WITH active_projects AS (

    SELECT DISTINCT execution_dim.project_id
    FROM {{ ref('structured_executions') }}
    INNER JOIN
    {{ ref('execution_dim') }} ON
        structured_executions.execution_id = execution_dim.execution_id
    WHERE structured_executions.command_category IN (
        'meltano invoke',
        'meltano elt',
        'meltano run',
        'meltano ui',
        'meltano test',
        'meltano schedule run'
    )
    AND execution_dim.event_created_at >= DATEADD(
        'month', -1, CURRENT_DATE()
    )
    -- GROUP BY 1
    -- HAVING SUM(structured_executions.event_count) > 1

    UNION ALL

    SELECT DISTINCT execution_dim.project_id
    FROM {{ ref('unstructured_executions') }}
    INNER JOIN
    {{ ref('execution_dim') }} ON
        unstructured_executions.execution_id = execution_dim.execution_id
    WHERE unstructured_executions.cli_command IN (
        'invoke',
        'elt',
        'run',
        'ui',
        'test'
    -- TODO: job run, schedule run?
    )
    AND execution_dim.event_created_at >= DATEADD(
        'month', -1, CURRENT_DATE()
    )
)

SELECT
    execution_dim.project_id,
    MAX(
        CASE WHEN active_projects.project_id IS NOT NULL THEN TRUE END
    ) AS is_active,
    MIN(execution_dim.event_created_at) AS first_event_at,
    MAX(execution_dim.event_created_at) AS last_event_at,
    SUM(
        CASE
            WHEN
                execution_dim.is_exec_event THEN execution_dim.event_count
            ELSE 0
        END
    ) AS exec_event_total
FROM {{ ref('execution_dim') }}
LEFT JOIN
    active_projects ON execution_dim.project_id = active_projects.project_id
GROUP BY 1
