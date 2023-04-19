WITH open_source_agg AS (
    SELECT
        cloud_execution_id,
        project_id AS oss_project_id,
        project_org_name AS oss_project_org_name,
        MIN(started_ts) AS oss_exec_started_ts,
        MAX(finished_ts) AS oss_exec_finished_ts,
        MIN(
            CASE WHEN cli_command = 'schedule' THEN started_ts END
        ) AS oss_run_started_ts,
        MIN(
            CASE WHEN cli_command = 'schedule' THEN finished_ts END
        ) AS oss_run_finished_ts
    FROM {{ ref('fact_cli_executions') }}
    WHERE cloud_execution_id IS NOT NULL
    GROUP BY 1, 2, 3

)

SELECT
    stg_dynamodb__workload_metadata_table.cloud_execution_id,
    stg_dynamodb__workload_metadata_table.cloud_project_id,
    stg_dynamodb__workload_metadata_table.tenant_resource_key,
    stg_dynamodb__projects_table.project_name,
    open_source_agg.oss_project_id,
    open_source_agg.oss_project_org_name,
    stg_dynamodb__project_schedules_table.interval AS schedule_interval,
    stg_dynamodb__project_schedules_table.is_enabled AS schedule_is_enabled,
    {# TRUE AS schedule_is_healthy, #}
    stg_dynamodb__project_schedules_table.cloud_deployment_name_hash,
    stg_dynamodb__workload_metadata_table.started_ts,
    stg_dynamodb__workload_metadata_table.finished_ts,
    stg_dynamodb__workload_metadata_table.cloud_exit_code,
    stg_dynamodb__workload_metadata_table.command_text_hash,
    stg_dynamodb__workload_metadata_table.cloud_job_name_hash,
    stg_dynamodb__workload_metadata_table.cloud_schedule_name_hash,
    cloud_schedule_frequency.schedule_freq_day,
    cloud_schedule_frequency.schedule_freq_rolling_avg,
    DATEDIFF(
        MILLISECOND,
        stg_dynamodb__workload_metadata_table.started_ts,
        stg_dynamodb__workload_metadata_table.finished_ts
    ) AS cloud_full_runtime_ms,
    DATEDIFF(
        MILLISECOND,
        open_source_agg.oss_run_started_ts,
        open_source_agg.oss_run_finished_ts
    ) AS cloud_billable_runtime_ms,
    COALESCE(
        cloud_schedule_frequency.schedule_freq_rolling_avg > 24, FALSE
    ) AS is_frequent_schedule,
    DATEDIFF(
        MILLISECOND,
        stg_dynamodb__workload_metadata_table.started_ts,
        open_source_agg.oss_run_started_ts
    ) AS cloud_startup_ms,
    DATEDIFF(
        MILLISECOND,
        open_source_agg.oss_exec_finished_ts,
        stg_dynamodb__workload_metadata_table.finished_ts
    ) AS cloud_teardown_ms,
    cloud_startup_ms + cloud_teardown_ms AS cloud_platform_runtime_ms,
    cloud_billable_runtime_ms / 60000.0 AS cloud_billable_runtime_minutes,
    CASE
        WHEN
            is_frequent_schedule
            THEN 0.5 + GREATEST(cloud_billable_runtime_minutes - 5, 0) * 0.1
        ELSE 1 + GREATEST(cloud_billable_runtime_minutes - 10, 0) * 0.1
    END AS credits_used_estimate,
    COALESCE(
        hash_lookup.unhashed_value,
        stg_dynamodb__workload_metadata_table.cloud_environment_name_hash
    ) AS env_name
FROM {{ ref('stg_dynamodb__workload_metadata_table') }}
LEFT JOIN {{ ref('stg_dynamodb__projects_table') }}
    ON
        stg_dynamodb__workload_metadata_table.cloud_project_id
        = stg_dynamodb__projects_table.cloud_project_id
LEFT JOIN {{ ref('stg_dynamodb__project_schedules_table') }}
    ON
        stg_dynamodb__workload_metadata_table.cloud_project_id
        = stg_dynamodb__project_schedules_table.cloud_project_id
        AND stg_dynamodb__workload_metadata_table.tenant_resource_key
        = stg_dynamodb__project_schedules_table.tenant_resource_key
        AND stg_dynamodb__workload_metadata_table.cloud_schedule_name_hash
        = stg_dynamodb__project_schedules_table.cloud_schedule_name_hash
LEFT JOIN open_source_agg
    ON
        stg_dynamodb__workload_metadata_table.cloud_execution_id
        = open_source_agg.cloud_execution_id
LEFT JOIN {{ ref('hash_lookup') }}
    ON
        stg_dynamodb__workload_metadata_table.cloud_environment_name_hash
        = hash_lookup.hash_value
        AND hash_lookup.category = 'environment'
LEFT JOIN {{ ref('cloud_schedule_frequency') }}
    ON
        stg_dynamodb__project_schedules_table.schedule_surrogate_key
        = cloud_schedule_frequency.schedule_surrogate_key
        AND stg_dynamodb__workload_metadata_table.started_ts::DATE
        = cloud_schedule_frequency.date_day
