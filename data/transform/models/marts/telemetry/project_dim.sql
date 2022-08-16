{{
    config(materialized='table')
}}

WITH active_projects AS (

    SELECT DISTINCT cli_executions_base.project_id
    FROM {{ ref('structured_executions') }}
    INNER JOIN
        {{ ref('cli_executions_base') }} ON
            structured_executions.execution_id
            = cli_executions_base.execution_id
    WHERE structured_executions.command_category IN (
        'meltano invoke',
        'meltano elt',
        'meltano run',
        'meltano ui',
        'meltano test'
    )
    AND cli_executions_base.event_created_at >= DATEADD(
        'month', -1, CURRENT_DATE()
    )

    UNION ALL

    SELECT DISTINCT cli_executions_base.project_id
    FROM {{ ref('unstructured_executions') }}
    INNER JOIN
        {{ ref('cli_executions_base') }} ON
            unstructured_executions.execution_id
            = cli_executions_base.execution_id
    WHERE unstructured_executions.cli_command IN (
        'invoke',
        'elt',
        'run',
        'ui',
        'test'
    )
    AND cli_executions_base.event_created_at >= DATEADD(
        'month', -1, CURRENT_DATE()
    )
),

first_project_source AS (

    SELECT DISTINCT
        project_id,
        FIRST_VALUE(
            CASE
                WHEN cli_command != 'init'
                    THEN project_uuid_source
            END
        ) IGNORE NULLS OVER (
            PARTITION BY project_id ORDER BY event_created_at ASC
        ) AS first_source
    FROM {{ ref('cli_executions_base') }}

)

SELECT
    cli_executions_base.project_id,
    MAX(
        COALESCE(active_projects.project_id IS NOT NULL, FALSE)
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
    ) AS exec_event_total,
    MAX(
        COALESCE(
            COALESCE(
                first_project_source.first_source,
                cli_executions_base.project_uuid_source
            ),
            'UNKNOWN'
        )
    ) AS project_id_source
FROM {{ ref('cli_executions_base') }}
LEFT JOIN
    active_projects ON
        cli_executions_base.project_id = active_projects.project_id
LEFT JOIN
    first_project_source ON
        cli_executions_base.project_id = first_project_source.project_id
GROUP BY 1
