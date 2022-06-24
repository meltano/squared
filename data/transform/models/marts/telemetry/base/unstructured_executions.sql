SELECT
    unstruct_exec_flattened.*,
    'snowplow' AS event_source,
    'unstructured' AS event_type
FROM {{ ref('unstruct_exec_flattened') }}
INNER JOIN
    {{ ref('event_src_activation') }} ON
        unstruct_exec_flattened.project_id = event_src_activation.project_id
WHERE
    unstruct_exec_flattened.started_ts >= event_src_activation.sp_activate_date
