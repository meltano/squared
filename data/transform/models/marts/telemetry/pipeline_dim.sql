SELECT DISTINCT
    pipeline_pk,
    project_id,
    env_id,
    is_test_pipeline,
    ARRAY_SIZE(plugins) AS plugin_count
FROM {{ ref('pipeline_executions') }}
