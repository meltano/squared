{{
    config(materialized='table')
}}

SELECT
    event_cli.event_id,
    event_cli.event,
    execution_mapping.execution_id,
    NULL AS block_type,
    context_exception.exception,
    stg_snowplow__events.event_created_at,
    context_plugins.plugins_obj,
    NULL AS exit_code,
    NULL AS exit_timestamp,
    NULL AS process_duration_microseconds
FROM {{ ref('event_cli') }}
LEFT JOIN {{ ref('execution_mapping') }}
    ON event_cli.event_id = execution_mapping.event_id
LEFT JOIN {{ ref('context_plugins') }}
    ON event_cli.event_id = context_plugins.event_id
LEFT JOIN {{ ref('context_exception') }}
    ON event_cli.event_id = context_exception.event_id
LEFT JOIN {{ ref('stg_snowplow__events') }}
    ON event_cli.event_id = stg_snowplow__events.event_id

UNION ALL

SELECT
    event_block.event_id,
    event_block.event,
    execution_mapping.execution_id,
    event_block.block_type,
    context_exception.exception,
    stg_snowplow__events.event_created_at,
    context_plugins.plugins_obj,
    NULL AS exit_code,
    NULL AS exit_timestamp,
    NULL AS process_duration_microseconds
FROM {{ ref('event_block') }}
LEFT JOIN {{ ref('execution_mapping') }}
    ON event_block.event_id = execution_mapping.event_id
LEFT JOIN {{ ref('context_plugins') }}
    ON event_block.event_id = context_plugins.event_id
LEFT JOIN {{ ref('context_exception') }}
    ON event_block.event_id = context_exception.event_id
LEFT JOIN {{ ref('stg_snowplow__events') }}
    ON event_block.event_id = stg_snowplow__events.event_id

UNION ALL

SELECT
    event_exit.event_id,
    'exit' AS event,
    execution_mapping.execution_id,
    NULL AS block_type,
    context_exception.exception,
    stg_snowplow__events.event_created_at,
    context_plugins.plugins_obj,
    event_exit.exit_code,
    event_exit.exit_timestamp,
    event_exit.process_duration_microseconds
FROM {{ ref('event_exit') }}
LEFT JOIN {{ ref('execution_mapping') }}
    ON event_exit.event_id = execution_mapping.event_id
LEFT JOIN {{ ref('context_plugins') }}
    ON event_exit.event_id = context_plugins.event_id
LEFT JOIN {{ ref('context_exception') }}
    ON event_exit.event_id = context_exception.event_id
LEFT JOIN {{ ref('stg_snowplow__events') }}
    ON event_exit.event_id = stg_snowplow__events.event_id
