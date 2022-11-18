WITH base AS (

    SELECT
        date_dim.date_day,
        date_dim.first_day_of_month,
        cli_executions_base.started_ts,
        cli_executions_base.finished_ts,
        cli_executions_base.cli_runtime_ms,
        cli_executions_base.execution_id,
        -- Project Attributes
        project_dim.project_id,
        project_dim.project_first_event_at,
        project_dim.project_last_event_at,
        project_dim.project_first_active_date,
        project_dim.project_last_active_date,
        project_dim.project_lifespan_days,
        project_dim.is_ephemeral_project_id,
        project_dim.project_id_source,
        project_dim.is_currently_active,
        -- Pipeline Attributes
        pipeline_dim.pipeline_pk AS pipeline_fk,
        pipeline_executions.pipeline_runtime_bin,
        cli_executions_base.event_count,
        cli_executions_base.cli_command,
        cli_executions_base.meltano_version,
        cli_executions_base.python_version,
        cli_executions_base.exit_code,
        cli_executions_base.is_ci_environment,
        cli_executions_base.is_exec_event,
        cli_executions_base.ip_address_hash,
        ip_address_dim.cloud_provider,
        ip_address_dim.execution_location,
        COALESCE(
            daily_active_projects.project_id IS NOT NULL,
            FALSE
        ) AS is_active_cli_execution,
        COALESCE(
            daily_active_projects_eom.project_id IS NOT NULL,
            FALSE
        ) AS is_active_eom_cli_execution
    FROM {{ ref('cli_executions_base') }}
    LEFT JOIN {{ ref('project_dim') }}
        ON cli_executions_base.project_id = project_dim.project_id
    LEFT JOIN {{ ref('pipeline_executions') }}
        ON cli_executions_base.execution_id = pipeline_executions.execution_id
    LEFT JOIN {{ ref('pipeline_dim') }}
        ON pipeline_executions.pipeline_pk = pipeline_dim.pipeline_pk
    LEFT JOIN {{ ref('date_dim') }}
        ON cli_executions_base.event_date = date_dim.date_day
    LEFT JOIN {{ ref('ip_address_dim') }}
        ON cli_executions_base.ip_address_hash = ip_address_dim.ip_address_hash
            AND cli_executions_base.event_created_at
            BETWEEN ip_address_dim.active_from AND COALESCE(
                ip_address_dim.active_to, CURRENT_TIMESTAMP
            )
    LEFT JOIN {{ ref('daily_active_projects') }}
        ON cli_executions_base.project_id = daily_active_projects.project_id
            AND date_dim.date_day = daily_active_projects.date_day
    LEFT JOIN {{ ref('daily_active_projects') }}
        AS daily_active_projects_eom -- noqa: L031
        ON cli_executions_base.project_id = daily_active_projects_eom.project_id
            AND CASE WHEN date_dim.last_day_of_month <= CURRENT_DATE
                THEN date_dim.last_day_of_month
                ELSE date_dim.date_day
            END = daily_active_projects_eom.date_day
),

project_segments_monthly AS (

    SELECT
        project_id,
        first_day_of_month,
        SUM(event_count) AS monthly_piplines_all,
        SUM(
            CASE WHEN is_active_cli_execution THEN event_count END
        ) AS monthly_piplines_active,
        SUM(
            CASE WHEN is_active_eom_cli_execution THEN event_count END
        ) AS monthly_piplines_active_eom,
        CASE
            WHEN SUM(event_count) < 50 THEN 'GUPPY'
            WHEN SUM(event_count) BETWEEN 50 AND 5000 THEN 'MARLIN'
            WHEN SUM(event_count) > 5000 THEN 'WHALE'
        END AS monthly_piplines_all_segment,
        CASE
            WHEN
                SUM(
                    CASE
                        WHEN is_active_cli_execution THEN event_count
                    END
                ) < 50 THEN 'GUPPY'
            WHEN
                SUM(
                    CASE
                        WHEN is_active_cli_execution THEN event_count
                    END
                ) BETWEEN 50 AND 5000 THEN 'MARLIN'
            WHEN
                SUM(
                    CASE
                        WHEN is_active_cli_execution THEN event_count
                    END
                ) > 5000 THEN 'WHALE'
        END AS monthly_piplines_active_segment,
        CASE
            WHEN
                SUM(
                    CASE
                        WHEN is_active_eom_cli_execution THEN event_count
                    END
                ) < 50 THEN 'GUPPY'
            WHEN
                SUM(
                    CASE
                        WHEN is_active_eom_cli_execution THEN event_count
                    END
                ) BETWEEN 50 AND 5000 THEN 'MARLIN'
            WHEN
                SUM(
                    CASE
                        WHEN is_active_eom_cli_execution THEN event_count
                    END
                ) > 5000 THEN 'WHALE'
        END AS monthly_piplines_active_eom_segment
    FROM base
    WHERE pipeline_fk IS NOT NULL
    GROUP BY 1, 2
)

SELECT
    base.date_day,
    base.started_ts,
    base.finished_ts,
    base.cli_runtime_ms,
    base.execution_id,
    base.project_id,
    base.project_first_event_at,
    base.project_last_event_at,
    base.project_first_active_date,
    base.project_last_active_date,
    base.project_lifespan_days,
    base.is_ephemeral_project_id,
    base.project_id_source,
    base.is_currently_active,
    base.pipeline_fk,
    base.pipeline_runtime_bin,
    base.event_count,
    base.cli_command,
    base.meltano_version,
    base.python_version,
    base.exit_code,
    base.is_ci_environment,
    base.is_exec_event,
    base.ip_address_hash,
    base.cloud_provider,
    base.execution_location,
    base.is_active_cli_execution,
    base.is_active_eom_cli_execution,
    project_segments_monthly.monthly_piplines_all,
    project_segments_monthly.monthly_piplines_active,
    project_segments_monthly.monthly_piplines_active_eom,
    COALESCE(
        project_segments_monthly.monthly_piplines_all_segment,
        'NO_PIPELINES'
    ) AS monthly_piplines_all_segment,
    COALESCE(
        project_segments_monthly.monthly_piplines_active_segment,
        'NO_PIPELINES'
    ) AS monthly_piplines_active_segment,
    COALESCE(
        project_segments_monthly.monthly_piplines_active_eom_segment,
        'NO_PIPELINES'
    ) AS monthly_piplines_active_eom_segment
FROM base
LEFT JOIN project_segments_monthly
    ON base.project_id = project_segments_monthly.project_id
        AND base.first_day_of_month
        = project_segments_monthly.first_day_of_month
