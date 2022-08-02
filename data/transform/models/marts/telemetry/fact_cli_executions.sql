SELECT
    date_dim.date_day,
    cli_executions_base.execution_id,
    cli_executions_base.project_id AS project_id,
    pipeline_dim.pipeline_pk AS pipeline_fk,
    cli_executions_base.event_count,
    cli_executions_base.cli_command,
    cli_executions_base.meltano_version,
    cli_executions_base.python_version,
    ip_address_dim.ip_address_hash,
    ip_address_dim.cloud_provider,
    ip_address_dim.execution_location,
    environment_dim.env_name
FROM {{ ref('cli_executions_base') }}
LEFT JOIN {{ ref('pipeline_executions') }}
    ON cli_executions_base.execution_id = pipeline_executions.execution_id
LEFT JOIN {{ ref('pipeline_dim') }}
    ON pipeline_executions.pipeline_pk = pipeline_dim.pipeline_pk
LEFT JOIN {{ ref('date_dim') }}
    ON cli_executions_base.event_date = date_dim.date_day
LEFT JOIN {{ ref('ip_address_dim') }}
    ON cli_executions_base.ip_address_hash = ip_address_dim.ip_address_hash
LEFT JOIN {{ ref('execution_env_map') }}
    ON cli_executions_base.execution_id = execution_env_map.execution_id
LEFT JOIN {{ ref('environment_dim') }}
    ON execution_env_map.environment_fk = environment_dim.environment_pk
