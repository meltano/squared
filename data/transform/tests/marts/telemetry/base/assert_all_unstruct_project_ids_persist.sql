-- Unstructured project ID either has Snowplow as active source
-- or its active in GA.
SELECT project_id FROM {{ ref('unstruct_exec_flattened') }}
MINUS
SELECT DISTINCT project_id FROM (
    SELECT DISTINCT project_id FROM {{ ref('event_src_activation') }}
    UNION
    SELECT DISTINCT project_id FROM {{ ref('stg_ga__cli_events') }}
)
