WITH base AS (
    SELECT
        project_id,
        date_day AS exec_date,
        COUNT(*) AS exec_count
    FROM prep.workspace.active_projects_base
    GROUP BY 1, 2
),
daily_project_active AS (
    SELECT DISTINCT
        date_dim.date_day,
        base.project_id
    FROM prep.workspace.date_dim
    INNER JOIN base
        ON base.exec_date BETWEEN DATEADD(
            DAY, -28, date_dim.date_day
        ) AND date_dim.date_day
)
SELECT
	sum(CASE WHEN FACT_CLI_EXECUTIONS.pipeline_fk IS NOT NULL THEN event_count end) AS all_pipeline_runs,
	sum(CASE WHEN FACT_CLI_EXECUTIONS.pipeline_fk IS NOT NULL and daily_project_active.project_id IS NOT NULL THEN event_count end) AS active_pipeline_runs,
	sum(CASE WHEN FACT_CLI_EXECUTIONS.pipeline_fk IS NOT NULL and daily_project_active.project_id IS NOT NULL THEN  datediff(millisecond, started_ts, finish_ts) end) AS active_runtime_ms,
	sum( CASE WHEN FACT_CLI_EXECUTIONS.pipeline_fk IS NOT NULL THEN datediff(millisecond, started_ts, finish_ts) END ) AS runtime_ms,
	count(DISTINCT CASE WHEN daily_project_active.project_id IS NOT NULL THEN pipeline_fk end) AS active_unique,
	count(DISTINCT pipeline_fk) AS all_unique,
	date_trunc('month', FACT_CLI_EXECUTIONS.DATE_DAY) as month_date
FROM prod.TELEMETRY.FACT_CLI_EXECUTIONS
LEFT JOIN daily_project_active
	ON FACT_CLI_EXECUTIONS.project_id = daily_project_active.project_id
	AND FACT_CLI_EXECUTIONS.DATE_DAY = daily_project_active.date_day
GROUP BY 7 ORDER BY 7 DESC;