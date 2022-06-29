{{
    config(materialized='table')
}}

SELECT
    unstruct_exec_flattened.*,
    cli_executions.event_source,
    cli_executions.event_created_at,
    cli_executions.event_created_date
FROM {{ ref('unstruct_exec_flattened') }}
INNER JOIN
    {{ ref('cli_executions') }} ON
        unstruct_exec_flattened.execution_id = cli_executions.execution_id
