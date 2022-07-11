SELECT
    date_dim.date_day,
    cli_executions_base.execution_id,
    cli_executions_base.project_id AS project_id,
    pipeline_dim.pipeline_pk AS pipeline_fk,
    cli_executions_base.event_count,
    cli_executions_base.cli_command
FROM {{ ref('cli_executions_base') }}
LEFT JOIN {{ ref('pipeline_executions') }}
    ON cli_executions_base.execution_id = pipeline_executions.execution_id
LEFT JOIN {{ ref('pipeline_dim') }}
    ON pipeline_executions.pipeline_pk = pipeline_dim.pipeline_pk
LEFT JOIN {{ ref('date_dim') }}
    ON cli_executions_base.event_date = date_dim.date_day
