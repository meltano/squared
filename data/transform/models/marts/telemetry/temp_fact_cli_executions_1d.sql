SELECT
    date_dim.date_day,
    cli_executions_base.started_ts,
    cli_executions_base.finished_ts,
    cli_executions_base.cli_runtime_ms,
    cli_executions_base.execution_id,
    cli_executions_base.project_id AS project_id,
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
        temp_daily_active_projects_1d.project_id IS NOT NULL,
        FALSE
    ) AS is_active_cli_execution,
    COALESCE(
        daily_active_projects_eom.project_id IS NOT NULL,
        FALSE
    ) AS is_active_eom_cli_execution
FROM {{ ref('cli_executions_base') }}
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
LEFT JOIN {{ ref('temp_daily_active_projects_1d') }}
    ON cli_executions_base.project_id = temp_daily_active_projects_1d.project_id
        AND date_dim.date_day = temp_daily_active_projects_1d.date_day
LEFT JOIN {{ ref('temp_daily_active_projects_1d') }}
    AS daily_active_projects_eom -- noqa: L031
    ON cli_executions_base.project_id = daily_active_projects_eom.project_id
        AND CASE WHEN date_dim.last_day_of_month <= CURRENT_DATE
            THEN date_dim.last_day_of_month
            ELSE date_dim.date_day
        END = daily_active_projects_eom.date_day
