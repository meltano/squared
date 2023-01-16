{% set mapping = {
    "NOT_RANDOM": {
        'filter': "project_id_source != 'random'"
    },
    "NOT_CI_ONLY": {
        'parent_name': 'NOT_RANDOM',
        'filter': "is_ci_only = FALSE"
    },
    "NOT_NULL_VERSION": {
        'parent_name': 'NOT_CI_ONLY',
        'filter': "(cohort_week < '2022-06-01' OR first_meltano_version != 'UNKNOWN')"
    },
    "NOT_OPT_OUT": {
        'parent_name': 'NOT_NULL_VERSION',
        'filter': "has_opted_out = FALSE"
	},
    "MINS_5_OR_LONGER": {
        'parent_name': 'NOT_OPT_OUT',
        'filter': "project_lifespan_mins > 5"
	},
    "ADD_OR_INSTALL_ATTEMPT": {
        'parent_name': 'MINS_5_OR_LONGER',
        'filter': "(add_count_all > 0 OR install_count_all > 0)"
	},
    "ADD_OR_INSTALL_SUCCESS": {
        'parent_name': 'ADD_OR_INSTALL_ATTEMPT',
        'filter': "(add_count_success > 0 OR install_count_success > 0)"
	},
    "EXEC_EVENT_ATTEMPT": {
        'parent_name': 'ADD_OR_INSTALL_SUCCESS',
        'filter': "exec_event_total > 0"
	},
    "EXEC_EVENT_SUCCESS": {
        'parent_name': 'EXEC_EVENT_ATTEMPT',
        'filter': "exec_event_success_total > 0"
	},
    "PIPELINE_ATTEMPT": {
        'parent_name': 'EXEC_EVENT_SUCCESS',
        'filter': "pipeline_runs_count_all > 0"
	},
    "PIPELINE_SUCCESS": {
        'parent_name': 'PIPELINE_ATTEMPT',
        'filter': "pipeline_runs_count_success > 0"
	},
    "ADD_OR_INSTALL_NON_GSG": {
        'parent_name': 'PIPELINE_SUCCESS',
        'filter': "non_gsg_add > 0"
	},
    "ADD_OR_INSTALL_NON_GSG_SUCCESS": {
        'parent_name': 'ADD_OR_INSTALL_NON_GSG',
        'filter': "non_gsg_add_success > 0"
	},
    "EXEC_NON_GSG": {
        'parent_name': 'ADD_OR_INSTALL_NON_GSG_SUCCESS',
        'filter': "non_gsg_exec > 0"
	},
    "EXEC_NON_GSG_SUCCESS": {
        'parent_name': 'EXEC_NON_GSG',
        'filter': "non_gsg_exec_success > 0"
	},
    "PIPELINE_NON_GSG": {
        'parent_name': 'EXEC_NON_GSG_SUCCESS',
        'filter': "non_gsg_pipeline > 0"
	},
    "PIPELINE_NON_GSG_SUCCESS": {
        'parent_name': 'PIPELINE_NON_GSG',
        'filter': "non_gsg_pipeline_success > 0"
	},
    "GREATER_1_DAY": {
        'parent_name': 'PIPELINE_NON_GSG_SUCCESS',
        'filter': "project_lifespan_hours >= 24"
	},
    "GREATER_7_DAY": {
        'parent_name': 'GREATER_1_DAY',
        'filter': "project_lifespan_hours >= (7*24)"
	},
    "ACTIVE_EXECUTION": {
        'parent_name': 'GREATER_7_DAY',
        'filter': "active_executions_count > 0"
	},
    "STILL_ACTIVE": {
        'parent_name': 'ACTIVE_EXECUTION',
        'filter': "is_currently_active = TRUE"
	}
	}
%}

WITH active_executions AS (

    SELECT
        project_id,
        SUM(
            CASE WHEN is_active_cli_execution THEN 1 END
        ) AS active_executions_count
    FROM {{ ref('fact_cli_executions') }}
    GROUP BY 1
),

project_base AS (

    SELECT
        project_dim.*,
        active_executions.active_executions_count,
        DATE_TRUNC(WEEK, project_dim.project_first_event_at) AS cohort_week
    FROM {{ ref('project_dim') }}
    LEFT JOIN active_executions
        ON project_dim.project_id = active_executions.project_id
    WHERE project_dim.is_codespace_demo = TRUE

),

agg_base AS (
    SELECT
        cohort_week,
        COUNT(
            DISTINCT project_id
        ) AS base_all,
        {% for filter_name, attribs in mapping.items() %}
        {{ compounding_funnel_filters(
			loop.index,
			filter_name,
			mapping,
			"COUNT(DISTINCT CASE WHEN TRUE",
			"THEN project_id END)"
		) }} AS {{ filter_name }}
			{%- if not loop.last %},{% endif -%}
		{% endfor %}
    FROM project_base
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