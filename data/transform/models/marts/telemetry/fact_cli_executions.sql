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
        project_dim.init_project_directory,
        project_dim.project_org_name,
        -- Pipeline Attributes
        pipeline_dim.pipeline_pk AS pipeline_fk,
        pipeline_executions.pipeline_runtime_bin,
        pipeline_executions.is_test_pipeline,
        cli_executions_base.event_count,
        cli_executions_base.cli_command,
        cli_executions_base.meltano_version,
        cli_executions_base.python_version,
        cli_executions_base.exit_code,
        cli_executions_base.is_ci_environment,
        cli_executions_base.is_exec_event,
        cli_executions_base.ip_address_hash,
        COALESCE(
            ip_address_dim.cloud_provider, 'UNKNOWN'
        ) AS cloud_provider,
        COALESCE(
            ip_address_dim.execution_location, 'UNKNOWN'
        ) AS execution_location,
        COALESCE(ip_address_dim.org_name, 'UNKNOWN') AS org_name,
        COALESCE(
            daily_active_projects.project_id IS NOT NULL,
            FALSE
        ) AS is_active_cli_execution,
        COALESCE(
            daily_active_projects_eom.project_id IS NOT NULL,
            FALSE
        ) AS is_active_eom_cli_execution,
        CASE
            WHEN ip_address_dim.cloud_provider = 'MELTANO_CLOUD'
                THEN REPLACE(cli_executions_base.client_uuid, '-', '')
        END AS cloud_execution_id
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
        ON
            cli_executions_base.ip_address_hash = ip_address_dim.ip_address_hash
            AND (
                ip_address_dim.active_from IS NULL
                OR cli_executions_base.event_created_at
                BETWEEN ip_address_dim.active_from AND COALESCE(
                    ip_address_dim.active_to, CURRENT_TIMESTAMP
                )
            )
    LEFT JOIN {{ ref('daily_active_projects') }}
        ON
            cli_executions_base.project_id = daily_active_projects.project_id
            AND date_dim.date_day = daily_active_projects.date_day
    LEFT JOIN
        {{ ref('daily_active_projects') }}
        AS daily_active_projects_eom -- noqa: L031
        ON
            cli_executions_base.project_id
            = daily_active_projects_eom.project_id
            AND CASE
                WHEN date_dim.last_day_of_month <= CURRENT_DATE
                    THEN date_dim.last_day_of_month
                ELSE date_dim.date_day
            END = daily_active_projects_eom.date_day
),

aggregates AS (

    SELECT
        project_id,
        first_day_of_month,
        CEIL(SUM(
            CASE
                WHEN is_active_eom_cli_execution THEN cli_runtime_ms
            END
        ) / 60000) AS total_cli_runtime_mins,
        SUM(event_count) AS monthly_piplines_all,
        SUM(
            CASE WHEN is_active_cli_execution THEN event_count END
        ) AS monthly_piplines_active,
        SUM(
            CASE WHEN is_active_eom_cli_execution THEN event_count END
        ) AS monthly_piplines_active_eom,
        COUNT(execution_id) AS total_execs,
        COUNT(
            CASE WHEN meltano_version != 'UNKNOWN' THEN execution_id END
        ) AS total_execs_w_version
    FROM base
    WHERE pipeline_fk IS NOT NULL
    GROUP BY 1, 2

),

project_segments_monthly AS (

    SELECT
        project_id,
        first_day_of_month,
        monthly_piplines_all,
        monthly_piplines_active,
        monthly_piplines_active_eom,
        CASE
            WHEN
                monthly_piplines_active_eom < 50 THEN 'GUPPY'
            WHEN
                monthly_piplines_active_eom BETWEEN 50 AND 2000 THEN 'MARLIN'
            WHEN
                monthly_piplines_active_eom > 2000 THEN 'WHALE'
        END AS monthly_piplines_active_eom_segment,
        CASE
            WHEN
                (
                    1.0 * total_execs_w_version / total_execs
                ) < 0.90 THEN 'INCONSISTENT_TIMING_DATA'
            WHEN
                total_cli_runtime_mins < 1000 THEN '<1,000'
            WHEN
                total_cli_runtime_mins
                BETWEEN 1000 AND 10000 THEN '1,000-10,000'
            WHEN
                total_cli_runtime_mins
                BETWEEN 10001 AND 30000 THEN '10,001-30,000'
            WHEN
                total_cli_runtime_mins
                BETWEEN 30001 AND 150000 THEN '30,001-150,000'
            WHEN
                total_cli_runtime_mins > 150001 THEN '150,001+'
        END AS monthly_runtime_mins_segment
    FROM aggregates
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
    base.init_project_directory,
    base.pipeline_fk,
    base.pipeline_runtime_bin,
    base.is_test_pipeline,
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
    base.project_org_name,
    base.org_name,
    base.cloud_execution_id,
    base.is_active_cli_execution,
    base.is_active_eom_cli_execution,
    project_segments_monthly.monthly_piplines_all,
    project_segments_monthly.monthly_piplines_active,
    project_segments_monthly.monthly_piplines_active_eom,
    prev_project_segments_monthly.monthly_piplines_active_eom
    AS monthly_piplines_previous,
    COALESCE(
        project_segments_monthly.monthly_piplines_active_eom_segment,
        'NO_PIPELINES'
    ) AS monthly_piplines_active_eom_segment,
    COALESCE(
        prev_project_segments_monthly.monthly_piplines_active_eom_segment,
        'NO_PIPELINES'
    ) AS monthly_piplines_previous_segment,
    COALESCE(
        project_segments_monthly.monthly_runtime_mins_segment,
        'NO_PIPELINES'
    ) AS monthly_runtime_mins_segment,
    COALESCE(
        prev_project_segments_monthly.monthly_runtime_mins_segment,
        'NO_PIPELINES'
    ) AS monthly_runtime_mins_previous_segment
FROM base
LEFT JOIN project_segments_monthly
    ON
        base.project_id = project_segments_monthly.project_id
        AND base.first_day_of_month
        = project_segments_monthly.first_day_of_month
LEFT JOIN
    project_segments_monthly
    AS prev_project_segments_monthly -- noqa: L031
    ON
        base.project_id = prev_project_segments_monthly.project_id
        AND DATEADD(MONTH, -1, base.first_day_of_month)
        = prev_project_segments_monthly.first_day_of_month
