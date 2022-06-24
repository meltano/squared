SELECT
    structured_events.event_id,
    cmd_parsed_all.environment AS env_hash,
    h1.unhashed_value AS env_name,
    NULL AS is_ephemeral,
    NULL AS is_cicd,
    NULL AS is_cloud
FROM {{ ref('structured_events') }}
LEFT JOIN
    {{ ref('cmd_parsed_all') }} ON
        structured_events.command = cmd_parsed_all.command
LEFT JOIN {{ ref('hash_lookup') }} as h1
    on cmd_parsed_all.environment = h1.hash_value
