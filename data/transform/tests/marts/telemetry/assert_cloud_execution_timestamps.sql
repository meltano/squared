SELECT
    cloud_execution_id
FROM {{ ref('fact_cloud_executions') }}
WHERE cloud_exit_code = 0
    AND cloud_full_runtime_ms != (cloud_startup_ms + cloud_schedule_runtime_ms + cloud_teardown_ms)
