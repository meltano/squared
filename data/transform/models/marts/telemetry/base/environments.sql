SELECT
    structured_events.event_id,
    cmd_parsed_all.environment AS env_hash,
    env_hash_mapping.name AS env_name,
    NULL AS is_ephemeral,
    NULL AS is_cicd,
    NULL AS is_cloud
FROM {{ ref('structured_events') }}
LEFT JOIN
    {{ ref('cmd_parsed_all') }} ON
        structured_events.command = cmd_parsed_all.command
-- TODO: add to hash lookup table all known environments, remvoe seed table, replace this join
LEFT JOIN
    {{ ref('env_hash_mapping') }} ON
        cmd_parsed_all.environment = env_hash_mapping.env_hash
