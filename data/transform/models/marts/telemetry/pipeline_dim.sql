SELECT DISTINCT
    pipeline_pk,
    project_id,
    env_id,
    ARRAY_SIZE(plugins) AS plugin_count,
    is_test_pipeline
FROM {{ ref('pipeline_executions') }}
