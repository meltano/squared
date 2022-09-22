{{
    config(materialized='table')
}}

WITH active_projects AS (

    SELECT DISTINCT project_id
    FROM {{ ref('daily_active_projects') }}
    WHERE date_day >= DATEADD(
        'day', -28, CURRENT_DATE()
    )

)

SELECT
    project_base.project_id,
    project_base.first_event_at,
    project_base.last_event_at,
    project_base.exec_event_total,
    project_base.project_id_source,
    COALESCE(active_projects.project_id IS NOT NULL, FALSE) AS is_active
FROM {{ ref('project_base') }}
LEFT JOIN
    active_projects ON
        project_base.project_id = active_projects.project_id
