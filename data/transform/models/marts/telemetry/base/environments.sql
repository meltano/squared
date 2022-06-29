SELECT
    structured_executions.event_id,
    cmd_parsed_all.environment AS env_hash,
    hash_lookup.unhashed_value AS env_name,
    NULL AS is_ephemeral,
    NULL AS is_cicd,
    NULL AS is_cloud
FROM {{ ref('structured_executions') }}
LEFT JOIN
    {{ ref('cmd_parsed_all') }} ON
        structured_executions.command = cmd_parsed_all.command
LEFT JOIN {{ ref('hash_lookup') }}
    ON cmd_parsed_all.environment = hash_lookup.hash_value
