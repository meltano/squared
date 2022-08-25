SELECT
    date_dim.date_day,
    cli_executions_base.started_ts,
    cli_executions_base.finish_ts,
    cli_executions_base.execution_id,
    cli_executions_base.project_id AS project_id,
    pipeline_dim.pipeline_pk AS pipeline_fk,
    cli_executions_base.event_count,
    cli_executions_base.cli_command,
    cli_executions_base.meltano_version,
    cli_executions_base.python_version,
    cli_executions_base.exit_code,
    cli_executions_base.is_ci_environment,
    cli_executions_base.is_exec_event,
    cli_executions_base.ip_address_hash,
    ip_address_dim.cloud_provider,
    ip_address_dim.execution_location
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
