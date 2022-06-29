{{
    config(materialized='table')
}}

SELECT
    cli_executions.event_source,
    stg_snowplow__events.derived_contexts,
    stg_snowplow__events.contexts,
    1 AS event_count,
    stg_snowplow__events.se_category AS command_category,
    stg_snowplow__events.se_action AS command,
    cli_executions.project_id,
    cli_executions.execution_id,
    cli_executions.event_created_at,
    cli_executions.event_created_date
FROM {{ ref('stg_snowplow__events') }}
INNER JOIN {{ ref('cli_executions') }}
    ON stg_snowplow__events.event_id = cli_executions.execution_id
WHERE cli_executions.event_type = 'structured'

UNION

SELECT
    cli_executions.event_source,
    NULL AS derived_contexts,
    NULL AS contexts,
    stg_ga__cli_events.event_count,
    stg_ga__cli_events.command_category,
    stg_ga__cli_events.command,
    cli_executions.project_id,
    cli_executions.execution_id,
    cli_executions.event_created_at,
    cli_executions.event_created_date
FROM {{ ref('stg_ga__cli_events') }}
INNER JOIN {{ ref('cli_executions') }}
    ON stg_ga__cli_events.event_surrogate_key = cli_executions.execution_id
