
WITH dates AS (
	SELECT 
		'2022-08-08' AS CUR,
		'2022-07-08' AS prev
)
SELECT count(DISTINCT project_id), 'total' FROM PREP.workspace.project_plugins_base WHERE date_day_28d = (SELECT CUR FROM dates)
AND days_from_first_event >= 7
UNION ALL
SELECT count(DISTINCT project_id), 'added' FROM (
	SELECT project_id FROM PREP.workspace.project_plugins_base WHERE date_day_28d = (SELECT CUR FROM dates)
	AND days_from_first_event >= 7
	minus
	SELECT project_id FROM PREP.workspace.project_plugins_base WHERE date_day_28d = (SELECT prev FROM dates)
	AND days_from_first_event >= 7
)
UNION all
SELECT count(DISTINCT project_id), 'lost' FROM (
	SELECT project_id FROM PREP.workspace.project_plugins_base WHERE date_day_28d = (SELECT prev FROM dates)
	AND days_from_first_event >= 7
	minus
	SELECT project_id FROM PREP.workspace.project_plugins_base WHERE date_day_28d = (SELECT CUR FROM dates)
	AND days_from_first_event >= 7
)
UNION all
SELECT count(DISTINCT project_id), 'reactivated' FROM (
	SELECT project_id FROM PREP.workspace.project_plugins_base WHERE date_day_28d = (SELECT CUR FROM dates)
	AND days_from_first_event >= 7
 	GROUP BY 1 HAVING min(days_from_first_event) > 30
	minus
	SELECT project_id FROM PREP.workspace.project_plugins_base WHERE date_day_28d = (SELECT prev FROM dates)
	AND days_from_first_event >= 7
);





-- Not working still
SELECT
        date_dim.date_day,
        (
	        SELECT count(DISTINCT project_id)
	        FROM PREP.workspace.project_plugins_base WHERE date_day_28d = date_dim.date_day
			AND days_from_first_event >= 7
        ) AS total_projects
        ,
        (
	        SELECT count(DISTINCT project_id) FROM (
				SELECT project_plugins_base.project_id FROM PREP.workspace.project_plugins_base WHERE project_plugins_base.date_day_28d = date_dim.date_day
				AND project_plugins_base.days_from_first_event >= 7
				minus
				SELECT project_plugins_base.project_id FROM PREP.workspace.project_plugins_base WHERE project_plugins_base.date_day_28d = dateadd(DAY, -1, date_dim.date_day)
				AND project_plugins_base.days_from_first_event >= 7
			)
		) AS added_projects
FROM prep.WORKSPACE.DATE_DIM
WHERE date_dim.date_day <= CURRENT_TIMESTAMP()
AND date_dim.date_day > '2022-08-01';



-- max days executing pipeline
WITH dates AS (
	SELECT 
		'2022-08-08' AS CUR,
		'2022-07-08' AS prev
),
pipeline_explorations AS (
	select PIPELINE_EXECUTIONS.*, cli_executions_base.event_created_at, fact_cli_projects.first_event_date, fact_cli_projects.lifespan_days, fact_cli_projects.events_total, fact_cli_projects.exec_event_total, fact_cli_projects.last_event_date
	from prep.workspace.PIPELINE_EXECUTIONS
	left join prod.telemetry.fact_cli_projects
	    on PIPELINE_EXECUTIONS.project_id = fact_cli_projects.project_id
	left join prep.workspace.cli_executions_base
	    on PIPELINE_EXECUTIONS.execution_id = cli_executions_base.execution_id
	where PIPELINE_EXECUTIONS.project_id in (
	    -- lost
	    SELECT DISTINCT project_id FROM (
	    	SELECT project_id FROM PREP.workspace.project_plugins_base WHERE date_day_28d = (SELECT prev FROM dates)
	    	AND days_from_first_event >= 7
	    	minus
	    	SELECT project_id FROM PREP.workspace.project_plugins_base WHERE date_day_28d = (SELECT CUR FROM dates)
	    	AND days_from_first_event >= 7
	    )
	)
),
base AS (
	SELECT
		project_id,
		DATE_TRUNC(week, event_created_at::date) AS week_date,
		count(DISTINCT event_created_at::date) AS days_executing
	from pipeline_explorations
	GROUP BY 1,2
),
base_2 AS (
SELECT 
	project_id,
	max(days_executing) AS m_d_e
FROM base
GROUP BY 1
)
SELECT
	m_d_e,
	count(DISTINCT project_id)
FROM base_2
GROUP BY 1
ORDER BY m_d_e desc;