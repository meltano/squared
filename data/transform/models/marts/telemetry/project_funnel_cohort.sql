{% set mapping = {
    "NOT_OPT_OUT": {
        'filter': "has_opted_out = FALSE"
	},
    "ADD_OR_INSTALL": {
        'parent_name': 'NOT_OPT_OUT',
        'filter': "(ARRAY_CONTAINS( 'add'::VARIANT, cli_command_array ) OR ARRAY_CONTAINS( 'install'::VARIANT, cli_command_array ))"
	},
    "EXEC_EVENT": {
        'parent_name': 'ADD_OR_INSTALL',
        'filter': "is_exec_event = TRUE"
	},
    "PIPELINE_ATTEMPT": {
        'parent_name': 'EXEC_EVENT',
        'filter': "ARRAY_SIZE( pipeline_array ) > 0"
	},
    "PIPELINE_SUCCESS": {
        'parent_name': 'PIPELINE_ATTEMPT',
        'filter': "ARRAY_CONTAINS( 'SUCCESS'::VARIANT, pipe_completion_statuses )"
	},
    "GREATER_1_DAY": {
        'parent_name': 'PIPELINE_SUCCESS',
        'filter': "project_lifespan_days >= 1"
	},
    "GREATER_7_DAY": {
        'parent_name': 'GREATER_1_DAY',
        'filter': "project_lifespan_days >= 7"
	},
    "STILL_ACTIVE": {
        'parent_name': 'GREATER_7_DAY',
        'filter': "is_currently_active = TRUE"
	}
	}
%}


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
        COUNT(
            DISTINCT CASE WHEN project_id_source != 'random'
                THEN project_id END
        ) AS base_all,
        {% for filter_name, attribs in mapping.items() %}
        {{ compounding_funnel_filters(
			loop.index,
			filter_name,
			mapping,
			"COUNT(DISTINCT CASE WHEN project_id_source != 'random'",
			"THEN project_id END)"
		) }} AS {{ filter_name }}
			{%- if not loop.last %},{% endif -%}
		{% endfor %}
    FROM cohort_execs
    GROUP BY 1
)


{% for filter_name, attribs in mapping.items() %}    

{%- if not loop.first %}
UNION ALL
{% endif -%}

SELECT
    cohort_week,
    '{{ loop.index }}' || '_' || '{{ filter_name }}' AS funnel_level,
    {{ filter_name }} AS funnel_level_value,
    {{ attribs.get('parent_name', 'base_all') }} AS parent_level_value,
    base_all
FROM agg_base

{% endfor %}
