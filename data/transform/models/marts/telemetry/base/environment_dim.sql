SELECT
    {{ dbt_utils.surrogate_key(
        [
            'structured_executions.project_id',
            'cmd_parsed_all.environment'
        ]
    ) }} AS environment_pk,
    structured_executions.project_id,
    cmd_parsed_all.environment AS env_hash,
    COALESCE(
        hash_lookup.unhashed_value,
        cmd_parsed_all.environment
    ) AS env_name
FROM {{ ref('structured_executions') }}
LEFT JOIN
    {{ ref('cmd_parsed_all') }} ON
        structured_executions.command = cmd_parsed_all.command
LEFT JOIN {{ ref('hash_lookup') }}
    ON cmd_parsed_all.environment = hash_lookup.hash_value
        AND hash_lookup.category = 'environment'

UNION ALL

SELECT
    {{ dbt_utils.surrogate_key(
        [
            'unstructured_executions.project_id',
            'unstructured_executions.environment_name_hash'
        ]
    ) }} AS environment_pk,
    unstructured_executions.project_id,
    unstructured_executions.environment_name_hash AS env_hash,
    COALESCE(
        hash_lookup.unhashed_value,
        unstructured_executions.environment_name_hash
    ) AS env_name
FROM {{ ref('unstructured_executions') }}
LEFT JOIN {{ ref('hash_lookup') }}
    ON unstructured_executions.environment_name_hash = hash_lookup.hash_value
        AND hash_lookup.category = 'environment'
