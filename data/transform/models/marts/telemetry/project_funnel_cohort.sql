{% set mapping = {
    "NOT_RANDOM": {
        'filter': "project_id_source != 'random'"
    },
    "NOT_CI_ONLY": {
        'parent_name': 'NOT_RANDOM',
        'filter': "is_ci_only_project = FALSE"
    },
    "NOT_NULL_VERSION": {
        'parent_name': 'NOT_CI_ONLY',
        'filter': "(cohort_week < '2022-06-01' OR first_meltano_version IS NOT NULL)"
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
        'filter': "(ARRAY_CONTAINS( 'add'::VARIANT, cli_command_array ) OR ARRAY_CONTAINS( 'install'::VARIANT, cli_command_array ))"
	},
    "ADD_OR_INSTALL_SUCCESS": {
        'parent_name': 'ADD_OR_INSTALL_ATTEMPT',
        'filter': "ARRAY_CONTAINS( 'SUCCESS'::VARIANT, add_or_install_completion_status )"
	},
    "EXEC_EVENT_ATTEMPT": {
        'parent_name': 'ADD_OR_INSTALL_SUCCESS',
        'filter': "is_exec_event_lifetime = TRUE"
	},
    "EXEC_EVENT_SUCCESS": {
        'parent_name': 'EXEC_EVENT_ATTEMPT',
        'filter': "ARRAY_CONTAINS( 'SUCCESS'::VARIANT, exec_event_completion_status )"
	},
    "PIPELINE_ATTEMPT": {
        'parent_name': 'EXEC_EVENT_SUCCESS',
        'filter': "ARRAY_SIZE( pipeline_array ) > 0"
	},
    "PIPELINE_SUCCESS": {
        'parent_name': 'PIPELINE_ATTEMPT',
        'filter': "ARRAY_CONTAINS( 'SUCCESS'::VARIANT, pipe_completion_statuses )"
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
        'filter': "is_active_cli_execution_lifetime = TRUE"
	},
    "STILL_ACTIVE": {
        'parent_name': 'ACTIVE_EXECUTION',
        'filter': "is_currently_active_lifetime = TRUE"
	}
	}
%}


WITH base AS (
    SELECT
        fact_cli_executions.*,
        fact_plugin_usage.completion_status,
        fact_plugin_usage.plugin_name,
        fact_plugin_usage.plugin_type,
        project_dim.project_lifespan_hours,
        COALESCE(opt_outs.project_id IS NOT NULL, FALSE) AS has_opted_out,
        DATEDIFF(
            'minute',
            fact_cli_executions.project_first_event_at,
            fact_cli_executions.project_last_event_at
        ) AS project_lifespan_mins
    FROM {{ ref('fact_cli_executions') }}
    LEFT JOIN {{ ref('fact_plugin_usage') }}
        ON fact_cli_executions.execution_id = fact_plugin_usage.execution_id
    LEFT JOIN prep.workspace.opt_outs
        ON fact_cli_executions.project_id = opt_outs.project_id
    LEFT JOIN {{ ref('project_dim') }}
        ON fact_cli_executions.project_id = project_dim.project_id
),

ci_only AS (
    SELECT
        base.project_id,
        MAX(is_ci_environment) AS is_ci_environment,
        COUNT(
            DISTINCT COALESCE(is_ci_environment, FALSE)
        ) AS is_ci_environment_count
    FROM base
    GROUP BY 1
    HAVING is_ci_environment_count = 1
),

project_attribs AS (
    SELECT
        project_id,
        MAX(is_exec_event) AS is_exec_event_lifetime,
        MAX(is_active_cli_execution) AS is_active_cli_execution_lifetime,
        MAX(is_currently_active) AS is_currently_active_lifetime,
        COUNT(
            DISTINCT CASE
                WHEN cli_command IN ('add', 'install')
                    AND plugin_name NOT IN (
                        'tap-gitlab',
                        'tap-github',
                        'target-jsonl',
                        'target-postgres'
                    )
                    AND plugin_type IN ('extractors', 'loaders')
                    THEN plugin_name
            END
        ) AS non_gsg_add,
        COUNT(
            DISTINCT CASE
                WHEN cli_command IN ('add', 'install')
                    AND plugin_name NOT IN (
                        'tap-gitlab',
                        'tap-github',
                        'target-jsonl',
                        'target-postgres'
                    )
                    AND plugin_type IN ('extractors', 'loaders')
                    AND completion_status = 'SUCCESS'
                    THEN plugin_name
            END
        ) AS non_gsg_add_success,
        COUNT(
            DISTINCT CASE
                WHEN is_exec_event
                    AND plugin_name NOT IN (
                        'tap-gitlab',
                        'tap-github',
                        'target-jsonl',
                        'target-postgres'
                    )
                    AND plugin_type IN ('extractors', 'loaders')
                    THEN plugin_name
            END
        ) AS non_gsg_exec,
        COUNT(
            DISTINCT CASE
                WHEN is_exec_event
                    AND plugin_name NOT IN (
                        'tap-gitlab',
                        'tap-github',
                        'target-jsonl',
                        'target-postgres'
                    )
                    AND plugin_type IN ('extractors', 'loaders')
                    AND completion_status = 'SUCCESS'
                    THEN plugin_name
            END
        ) AS non_gsg_exec_success,
        COUNT(
            DISTINCT CASE
                WHEN pipeline_fk IS NOT NULL
                    AND plugin_name NOT IN (
                        'tap-gitlab',
                        'tap-github',
                        'target-jsonl',
                        'target-postgres'
                    )
                    AND plugin_type IN ('extractors', 'loaders')
                    THEN plugin_name
            END
        ) AS non_gsg_pipeline,
        COUNT(
            DISTINCT CASE
                WHEN pipeline_fk IS NOT NULL
                    AND plugin_name NOT IN (
                        'tap-gitlab',
                        'tap-github',
                        'target-jsonl',
                        'target-postgres'
                    )
                    AND plugin_type IN ('extractors', 'loaders')
                    AND completion_status = 'SUCCESS'
                    THEN plugin_name
            END
        ) AS non_gsg_pipeline_success
    FROM base
    GROUP BY 1
),

cohort_execs AS (
    SELECT
        base.*,
        project_attribs.is_exec_event_lifetime,
        project_attribs.is_active_cli_execution_lifetime,
        project_attribs.is_currently_active_lifetime,
        project_attribs.non_gsg_add,
        project_attribs.non_gsg_add_success,
        project_attribs.non_gsg_exec,
        project_attribs.non_gsg_exec_success,
        project_attribs.non_gsg_pipeline,
        project_attribs.non_gsg_pipeline_success,
        DATE_TRUNC(WEEK, base.project_first_event_at) AS cohort_week,
        ARRAY_AGG(
            DISTINCT CASE
                WHEN base.pipeline_fk IS NOT NULL THEN base.completion_status
            END
        ) OVER (PARTITION BY base.project_id) AS pipe_completion_statuses,
        ARRAY_AGG(
            DISTINCT CASE
                WHEN
                    base.cli_command IN (
                        'add', 'install'
                    ) THEN base.completion_status
            END
        ) OVER (
            PARTITION BY base.project_id
        ) AS add_or_install_completion_status,
        ARRAY_AGG(
            DISTINCT CASE
                WHEN base.is_exec_event THEN base.completion_status
            END
        ) OVER (PARTITION BY base.project_id) AS exec_event_completion_status,
        ARRAY_AGG(
            DISTINCT base.pipeline_fk
        ) OVER (PARTITION BY base.project_id) AS pipeline_array,
        ARRAY_AGG(
            DISTINCT base.cli_command
        ) OVER (PARTITION BY base.project_id) AS cli_command_array,
        COALESCE(
            ci_only.project_id IS NOT NULL AND ci_only.is_ci_environment = TRUE,
            FALSE
        ) AS is_ci_only_project,
        FIRST_VALUE(
            base.meltano_version
        ) OVER (
            PARTITION BY
                base.project_id
            ORDER BY COALESCE(base.started_ts, base.date_day) ASC
        ) AS first_meltano_version
    FROM base
    LEFT JOIN ci_only
        ON base.project_id = ci_only.project_id
    LEFT JOIN project_attribs
        ON base.project_id = project_attribs.project_id

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
