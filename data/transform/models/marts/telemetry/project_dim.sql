WITH active_projects AS (

    SELECT
		project_id,
		MIN(date_day) AS first_active_date,
		MAX(date_day) AS last_active_date
	FROM {{ ref('daily_active_projects') }}
    GROUP BY 1

)

SELECT
    project_base.project_id,
    project_base.first_event_at AS project_first_event_at,
    project_base.last_event_at AS project_last_event_at,
    project_base.exec_event_total,
    project_base.project_id_source,
    active_projects.first_active_date AS project_first_active_date,
    active_projects.last_active_date AS project_last_active_date,
    COALESCE(active_projects.last_active_date = CURRENT_DATE(), FALSE) AS is_currently_active,
    project_base.lifespan_days AS project_lifespan_days,
    project_base.lifespan_hours AS project_lifespan_hours,
    COALESCE(
        project_base.lifespan_hours <= 24
        AND project_base.first_event_at::DATE != CURRENT_DATE,
        FALSE
    ) AS is_ephemeral_project_id
FROM {{ ref('project_base') }}
LEFT JOIN
    active_projects ON
        project_base.project_id = active_projects.project_id
