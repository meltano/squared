{{
    config(materialized='table')
}}

SELECT
    unstruct_exec_flattened.*,
    cli_execs_blended.event_source,
    cli_execs_blended.event_created_at,
    cli_execs_blended.event_created_date
FROM {{ ref('unstruct_exec_flattened') }}
INNER JOIN
    {{ ref('cli_execs_blended') }} ON
    unstruct_exec_flattened.execution_id = cli_execs_blended.execution_id
