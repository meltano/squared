{{
    config(materialized='table')
}}

SELECT
    'snowplow' AS event_source,
    'unstructured' AS event_type,
    unstruct_exec_flattened.project_id,
    unstruct_exec_flattened.execution_id,
    unstruct_exec_flattened.started_ts AS event_created_at,
    unstruct_exec_flattened.started_ts::DATE AS event_created_date
FROM {{ ref('unstruct_exec_flattened') }}
INNER JOIN
    {{ ref('event_src_activation') }} ON
        unstruct_exec_flattened.project_id = event_src_activation.project_id
WHERE
    unstruct_exec_flattened.started_ts >= event_src_activation.sp_activate_date

UNION ALL

SELECT
    'snowplow' AS event_source,
    'structured' AS event_type,
    stg_snowplow__events.se_label AS project_id,
    stg_snowplow__events.event_id,
    stg_snowplow__events.event_created_at,
    stg_snowplow__events.event_created_date
FROM {{ ref('stg_snowplow__events') }}
INNER JOIN
    {{ ref('event_src_activation') }} ON
        stg_snowplow__events.se_label = event_src_activation.project_id
WHERE
    stg_snowplow__events.event_created_date
    >= event_src_activation.sp_activate_date
    -- Only count legacy structured events without context.
    -- Structured with context will be rolled up into unstructured
    AND stg_snowplow__events.contexts IS NULL
    AND stg_snowplow__events.app_id = 'meltano'

UNION ALL

SELECT
    'ga' AS event_source,
    'structured' AS event_type,
    stg_ga__cli_events.project_id,
    stg_ga__cli_events.event_surrogate_key AS event_id,
    stg_ga__cli_events.event_date AS event_created_at,
    stg_ga__cli_events.event_date AS event_created_date
FROM {{ ref('stg_ga__cli_events') }}
LEFT JOIN
    {{ ref('event_src_activation') }} ON
        stg_ga__cli_events.project_id = event_src_activation.project_id
WHERE
    (event_src_activation.sp_activate_date IS NULL
        OR stg_ga__cli_events.event_date < event_src_activation.sp_activate_date
    )
