SELECT
    structured_events.event_id,
    structured_parsing_combined.environment AS env_hash,
    env_hash_mapping.name AS env_name,
    NULL AS is_ephemeral,
    NULL AS is_cicd,
    NULL AS is_cloud
FROM {{ ref('structured_events') }}
LEFT JOIN {{ ref('structured_parsing_combined') }} on structured_events.command = structured_parsing_combined.command
LEFT JOIN {{ ref('env_hash_mapping') }} on structured_parsing_combined.environment = env_hash_mapping.env_hash
