{{
    config(materialized='table')
}}

SELECT
    cli_executions_blended.event_source,
    stg_snowplow__events.derived_contexts,
    stg_snowplow__events.contexts,
    1 AS event_count,
    stg_snowplow__events.se_category AS command_category,
    stg_snowplow__events.se_action AS command,
    cli_executions_blended.project_id,
    cli_executions_blended.execution_id,
    cli_executions_blended.event_created_at,
    cli_executions_blended.event_created_date
FROM {{ ref('stg_snowplow__events') }}
INNER JOIN {{ ref('cli_executions_blended') }}
    ON stg_snowplow__events.event_id = cli_executions_blended.execution_id
WHERE cli_executions_blended.event_type = 'structured'

UNION

SELECT
    cli_executions_blended.event_source,
    NULL AS derived_contexts,
    NULL AS contexts,
    stg_ga__cli_events.event_count,
    stg_ga__cli_events.command_category,
    stg_ga__cli_events.command,
    cli_executions_blended.project_id,
    cli_executions_blended.execution_id,
    cli_executions_blended.event_created_at,
    cli_executions_blended.event_created_date
FROM {{ ref('stg_ga__cli_events') }}
INNER JOIN {{ ref('cli_executions_blended') }}
    ON stg_ga__cli_events.event_surrogate_key = cli_executions_blended.execution_id
