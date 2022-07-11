{{
    config(materialized='table')
}}

WITH active_projects AS (

    SELECT DISTINCT cli_executions_base.project_id
    FROM {{ ref('structured_executions') }}
    INNER JOIN
    {{ ref('cli_executions_base') }} ON
        structured_executions.execution_id = cli_executions_base.execution_id
    WHERE structured_executions.command_category IN (
        'meltano invoke',
        'meltano elt',
        'meltano run',
        'meltano ui',
        'meltano test',
        'meltano schedule run'
    )
    AND cli_executions_base.event_created_at >= DATEADD(
        'month', -1, CURRENT_DATE()
    )
    -- GROUP BY 1
    -- HAVING SUM(structured_executions.event_count) > 1

    UNION ALL

    SELECT DISTINCT cli_executions_base.project_id
    FROM {{ ref('unstructured_executions') }}
    INNER JOIN
    {{ ref('cli_executions_base') }} ON
        unstructured_executions.execution_id = cli_executions_base.execution_id
    WHERE unstructured_executions.cli_command IN (
        'invoke',
        'elt',
        'run',
        'ui',
        'test'
    -- TODO: job run, schedule run?
    )
    AND cli_executions_base.event_created_at >= DATEADD(
        'month', -1, CURRENT_DATE()
    )
)

SELECT
    cli_executions_base.project_id,
    MAX(
        CASE WHEN active_projects.project_id IS NOT NULL THEN TRUE END
    ) AS is_active,
    MIN(cli_executions_base.event_created_at) AS first_event_at,
    MAX(cli_executions_base.event_created_at) AS last_event_at,
    SUM(
        CASE
            WHEN
                cli_executions_base.is_exec_event
                THEN cli_executions_base.event_count
            ELSE 0
        END
    ) AS exec_event_total
FROM {{ ref('cli_executions_base') }}
LEFT JOIN
    active_projects ON
        cli_executions_base.project_id = active_projects.project_id
GROUP BY 1
