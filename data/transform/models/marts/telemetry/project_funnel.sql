WITH base AS (
	SELECT
		FACT_CLI_EXECUTIONS.*,
		FACT_PLUGIN_USAGE.completion_status,
		COALESCE(opt_outs.project_id IS NOT NULL, FALSE) AS has_opted_out
	FROM {{ ref('fact_cli_executions') }}
	LEFT JOIN {{ ref('fact_plugin_usage') }}
		ON fact_cli_executions.execution_id = FACT_PLUGIN_USAGE.execution_id
	LEFT JOIN prep.workspace.opt_outs 
		ON fact_cli_executions.project_id = opt_outs.project_id
),
init_cohort AS (
	SELECT
		DISTINCT project_id
	FROM base
	WHERE base.cli_command = 'init'
),
cohort_execs AS (
	SELECT
		DATE_TRUNC(week, PROJECT_FIRST_EVENT_AT) AS cohort_week,
		base.*,
		array_agg(DISTINCT CASE WHEN PIPELINE_FK IS NOT NULL THEN completion_status end) OVER (PARTITION BY base.project_id) AS pipe_completion_statuses,
		array_agg(DISTINCT PIPELINE_FK) OVER (PARTITION BY base.project_id) AS pipeline_array,
		array_agg(DISTINCT cli_command) OVER (PARTITION BY base.project_id) AS cli_command_array
	FROM base
    -- Drop projects that didnt init
	INNER JOIN init_cohort
	    ON base.project_id = init_cohort.project_id
)
SELECT
	cohort_week,
	count(DISTINCT project_id) AS all_projects,
	count(DISTINCT IP_ADDRESS_HASH) AS all_ips,
	count(DISTINCT CASE WHEN PROJECT_ID_SOURCE != 'random' THEN project_id end) AS project_id_not_random,
	count(DISTINCT CASE WHEN PROJECT_ID_SOURCE != 'random' AND NOT IS_EPHEMERAL_PROJECT_ID THEN project_id end) AS projects_not_ephemeral,
	count(DISTINCT CASE WHEN PROJECT_ID_SOURCE != 'random' AND NOT IS_EPHEMERAL_PROJECT_ID AND has_opted_out = FALSE THEN project_id end) AS projects_not_opted_out,
	count(DISTINCT CASE WHEN PROJECT_ID_SOURCE != 'random' AND NOT IS_EPHEMERAL_PROJECT_ID AND has_opted_out = FALSE AND ARRAY_CONTAINS('add'::VARIANT, cli_command_array) THEN project_id end) projects_add_plugin,
	count(DISTINCT CASE WHEN PROJECT_ID_SOURCE != 'random' AND NOT IS_EPHEMERAL_PROJECT_ID AND has_opted_out = FALSE AND ARRAY_CONTAINS('add'::VARIANT, cli_command_array) AND ARRAY_SIZE(pipeline_array) > 0 THEN project_id end) projects_pipeline_attempts,
	count(DISTINCT CASE WHEN PROJECT_ID_SOURCE != 'random' AND NOT IS_EPHEMERAL_PROJECT_ID AND has_opted_out = FALSE AND ARRAY_CONTAINS('add'::VARIANT, cli_command_array) AND ARRAY_SIZE(pipeline_array) > 0 AND ARRAY_CONTAINS('SUCCESS'::VARIANT, pipe_completion_statuses) THEN project_id end) projects_pipeline_success,
	count(DISTINCT CASE WHEN PROJECT_ID_SOURCE != 'random' AND NOT IS_EPHEMERAL_PROJECT_ID AND has_opted_out = FALSE AND ARRAY_CONTAINS('add'::VARIANT, cli_command_array) AND ARRAY_SIZE(pipeline_array) > 0 AND ARRAY_CONTAINS('SUCCESS'::VARIANT, pipe_completion_statuses) AND PROJECT_LIFESPAN_DAYS >= 7 THEN project_id end) projects_success_grt_7d,
	count(DISTINCT CASE WHEN PROJECT_ID_SOURCE != 'random' AND NOT IS_EPHEMERAL_PROJECT_ID AND has_opted_out = FALSE AND ARRAY_CONTAINS('add'::VARIANT, cli_command_array) AND ARRAY_SIZE(pipeline_array) > 0 AND ARRAY_CONTAINS('SUCCESS'::VARIANT, pipe_completion_statuses) AND IS_CURRENTLY_ACTIVE THEN project_id end) projects_success_still_active,
	count(DISTINCT CASE WHEN PROJECT_LIFESPAN_DAYS >= 7 THEN project_id end) all_grt_7_days,
	count(DISTINCT CASE WHEN IS_CURRENTLY_ACTIVE THEN project_id end) all_still_active_today,
	count(DISTINCT CASE WHEN PIPELINE_FK IS NOT NULL AND completion_status != 'SUCCESS' THEN project_id end) all_where_pipeline_fail,
	count(DISTINCT CASE WHEN IS_EPHEMERAL_PROJECT_ID THEN project_id end) all_ephemeral_projects
FROM cohort_execs
GROUP BY 1
