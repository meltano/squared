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
            DISTINCT CASE WHEN project_id_source != 'random' THEN project_id END
        ) AS all_projects,
        COUNT(
            DISTINCT CASE
                WHEN
                    project_id_source != 'random' AND has_opted_out = FALSE THEN project_id
            END
        ) AS projects_not_opted_out,
        COUNT(
            DISTINCT CASE
                WHEN
                    project_id_source != 'random' AND has_opted_out = FALSE AND (
                        ARRAY_CONTAINS(
                            'add'::VARIANT, cli_command_array
                        ) OR ARRAY_CONTAINS(
                            'install'::VARIANT, cli_command_array
                        )
                    ) THEN project_id
            END
        ) AS projects_add_or_install_plugin,
        COUNT(
            DISTINCT CASE
                WHEN
                    project_id_source != 'random' AND has_opted_out = FALSE AND (
                        ARRAY_CONTAINS(
                            'add'::VARIANT, cli_command_array
                        ) OR ARRAY_CONTAINS(
                            'install'::VARIANT, cli_command_array
                        )
                    ) AND is_exec_event = TRUE THEN project_id
            END
        ) AS projects_exec_event,
        COUNT(
            DISTINCT CASE
                WHEN
                    project_id_source != 'random' AND has_opted_out = FALSE AND (
                        ARRAY_CONTAINS(
                            'add'::VARIANT, cli_command_array
                        ) OR ARRAY_CONTAINS(
                            'install'::VARIANT, cli_command_array
                        )
                    ) AND is_exec_event = TRUE AND ARRAY_SIZE(
                        pipeline_array
                    ) > 0 THEN project_id
            END
        ) AS projects_pipeline_attempts,
        COUNT(
            DISTINCT CASE
                WHEN
                    project_id_source != 'random' AND has_opted_out = FALSE AND (
                        ARRAY_CONTAINS(
                            'add'::VARIANT, cli_command_array
                        ) OR ARRAY_CONTAINS(
                            'install'::VARIANT, cli_command_array
                        )
                    ) AND is_exec_event = TRUE AND ARRAY_SIZE(
                        pipeline_array
                    ) > 0 AND ARRAY_CONTAINS(
                        'SUCCESS'::VARIANT, pipe_completion_statuses
                    ) THEN project_id
            END
        ) AS projects_pipeline_success,
        COUNT(
            DISTINCT CASE
                WHEN
                    project_id_source != 'random' AND has_opted_out = FALSE AND (
                        ARRAY_CONTAINS(
                            'add'::VARIANT, cli_command_array
                        ) OR ARRAY_CONTAINS(
                            'install'::VARIANT, cli_command_array
                        )
                    ) AND is_exec_event = TRUE AND ARRAY_SIZE(
                        pipeline_array
                    ) > 0 AND ARRAY_CONTAINS(
                        'SUCCESS'::VARIANT, pipe_completion_statuses
                    ) AND project_lifespan_days >= 1 THEN project_id
            END
        ) AS projects_success_grt_1d,
        COUNT(
            DISTINCT CASE
                WHEN
                    project_id_source != 'random' AND has_opted_out = FALSE AND (
                        ARRAY_CONTAINS(
                            'add'::VARIANT, cli_command_array
                        ) OR ARRAY_CONTAINS(
                            'install'::VARIANT, cli_command_array
                        )
                    ) AND is_exec_event = TRUE AND ARRAY_SIZE(
                        pipeline_array
                    ) > 0 AND ARRAY_CONTAINS(
                        'SUCCESS'::VARIANT, pipe_completion_statuses
                    ) AND project_lifespan_days >= 7 THEN project_id
            END
        ) AS projects_success_grt_7d,
        COUNT(
            DISTINCT CASE
                WHEN
                    project_id_source != 'random' AND has_opted_out = FALSE AND (
                        ARRAY_CONTAINS(
                            'add'::VARIANT, cli_command_array
                        ) OR ARRAY_CONTAINS(
                            'install'::VARIANT, cli_command_array
                        )
                    ) AND is_exec_event = TRUE AND ARRAY_SIZE(
                        pipeline_array
                    ) > 0 AND ARRAY_CONTAINS(
                        'SUCCESS'::VARIANT, pipe_completion_statuses
                    ) AND is_currently_active THEN project_id
            END
        ) AS projects_success_still_active,
        COUNT(
            DISTINCT CASE WHEN project_lifespan_days >= 7 THEN project_id END
        ) AS all_grt_7_days,
        COUNT(
            DISTINCT CASE WHEN is_currently_active THEN project_id END
        ) AS all_still_active_today,
        COUNT(
            DISTINCT CASE
                WHEN
                    pipeline_fk IS NOT NULL AND completion_status != 'SUCCESS' THEN project_id
            END
        ) AS all_where_pipeline_fail,
        COUNT(
            DISTINCT CASE WHEN is_ephemeral_project_id THEN project_id END
        ) AS all_ephemeral_projects
    FROM cohort_execs
    GROUP BY 1
)

{% set mapping = {
	"NOT_OPT_OUT": 'projects_not_opted_out',
	"ADD_OR_INSTALL": 'projects_add_or_install_plugin',
	"EXEC_EVENT": 'projects_exec_event',
	"PIPELINE_ATTEMPT": 'projects_pipeline_attempts',
	"PIPELINE_SUCCESS": 'projects_pipeline_success',
	"GREATER_1_DAY": 'projects_success_grt_1d',
	"GREATER_7_DAY": 'projects_success_grt_7d',
	"STILL_ACTIVE": 'projects_success_still_active'
	}
%}

    {% for name, value in mapping.items() %}    

{%- if not loop.first %}
UNION ALL
    {% endif -%}

SELECT
        cohort_week,
        '{{ name }}' AS funnel_level,
        {{ value }} AS funnel_level_value,
        all_projects
    FROM agg_base

    {% endfor %}
