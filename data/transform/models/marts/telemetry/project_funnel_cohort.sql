WITH base AS (
    SELECT
        fact_cli_executions.*,
        fact_plugin_usage.completion_status,
        COALESCE(opt_outs.project_id IS NOT NULL, FALSE) AS has_opted_out
    FROM {{ ref('fact_cli_executions') }}
    LEFT JOIN {{ ref('fact_plugin_usage') }}
        ON fact_cli_executions.execution_id = fact_plugin_usage.execution_id
    LEFT JOIN prep.workspace.opt_outs
        ON fact_cli_executions.project_id = opt_outs.project_id
),

cohort_execs AS (
    SELECT
        base.*,
        DATE_TRUNC(WEEK, base.project_first_event_at) AS cohort_week,
        ARRAY_AGG(
            DISTINCT CASE
                WHEN base.pipeline_fk IS NOT NULL THEN base.completion_status
            END
        ) OVER (PARTITION BY base.project_id) AS pipe_completion_statuses,
        ARRAY_AGG(
            DISTINCT base.pipeline_fk
        ) OVER (PARTITION BY base.project_id) AS pipeline_array,
        ARRAY_AGG(
            DISTINCT base.cli_command
        ) OVER (PARTITION BY base.project_id) AS cli_command_array
    FROM base
),

agg_base AS (
    SELECT
        cohort_week,
        COUNT(DISTINCT ip_address_hash) AS all_ips,
        COUNT(
            DISTINCT CASE WHEN {{ funnel_filter(0) }} THEN project_id END
        ) AS all_projects,
        COUNT(
            DISTINCT CASE
                WHEN
                    {{ funnel_filter(1) }} THEN project_id
            END
        ) AS projects_not_opted_out,
        COUNT(
            DISTINCT CASE
                WHEN
                    {{ funnel_filter(2) }} THEN project_id
            END
        ) AS projects_add_or_install_plugin,
        COUNT(
            DISTINCT CASE
                WHEN
                    {{ funnel_filter(3) }} THEN project_id
            END
        ) AS projects_exec_event,
        COUNT(
            DISTINCT CASE
                WHEN
                    {{ funnel_filter(4) }} THEN project_id
            END
        ) AS projects_pipeline_attempts,
        COUNT(
            DISTINCT CASE
                WHEN
                    {{ funnel_filter(5) }} THEN project_id
            END
        ) AS projects_pipeline_success,
        COUNT(
            DISTINCT CASE
                WHEN
                    {{ funnel_filter(6) }} THEN project_id
            END
        ) AS projects_success_grt_1d,
        COUNT(
            DISTINCT CASE
                WHEN
                    {{ funnel_filter(7) }} THEN project_id
            END
        ) AS projects_success_grt_7d,
        COUNT(
            DISTINCT CASE
                WHEN
                   {{ funnel_filter(8) }} THEN project_id
            END
        ) AS projects_success_still_active
    FROM cohort_execs
    GROUP BY 1
)

{% set mapping = {
	"1_NOT_OPT_OUT": {
		'name': 'projects_not_opted_out',
		'parent_name': 'all_projects',
		'query': "has_opted_out = FALSE"
	},
	"2_ADD_OR_INSTALL": {
		'name': 'projects_add_or_install_plugin',
		'parent_name': 'projects_not_opted_out',
		'query': "ARRAY_CONTAINS( 'add'::VARIANT, cli_command_array ) OR ARRAY_CONTAINS( 'install'::VARIANT, cli_command_array )"
	},
	"3_EXEC_EVENT": {
		'name': 'projects_exec_event',
		'parent_name': 'projects_add_or_install_plugin'
	},
	"4_PIPELINE_ATTEMPT": {
		'name': 'projects_pipeline_attempts',
		'parent_name': 'projects_exec_event'
	},
	"5_PIPELINE_SUCCESS": {
		'name': 'projects_pipeline_success',
		'parent_name': 'projects_pipeline_attempts'
	},
	"6_GREATER_1_DAY": {
		'name': 'projects_success_grt_1d',
		'parent_name': 'projects_pipeline_success'
	},
	"7_GREATER_7_DAY": {
		'name': 'projects_success_grt_7d',
		'parent_name': 'projects_success_grt_1d'
	},
	"8_STILL_ACTIVE": {
		'name': 'projects_success_still_active',
		'parent_name': 'projects_success_grt_7d'
	}
	}
%}

    {% for filter_name, attribs in mapping.items() %}    

{%- if not loop.first %}
UNION ALL
    {% endif -%}

SELECT
        cohort_week,
        '{{ filter_name }}' AS funnel_level,
        {{ attribs['name'] }} AS funnel_level_value,
		{{ attribs['parent_name'] }} AS parent_level_value,
        all_projects
    FROM agg_base

    {% endfor %}
