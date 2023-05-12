WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY execution_id
            ORDER BY _sdc_batched_at::TIMESTAMP_NTZ DESC
        ) AS row_num
    FROM {{ source('tap_dynamodb', 'workload_metadata_table') }}
),

renamed AS (

    SELECT
        ecs_task_status,
        NULLIF(end_time, 'N/A')::TIMESTAMP_NTZ AS finished_ts,
        execution_id AS cloud_execution_id,
        NULLIF(exit_code, 'N/A')::INT AS cloud_exit_code,
        NULLIF(start_time, 'N/A')::TIMESTAMP_NTZ AS started_ts,
        ttl::INT AS cloud_run_ttl,
        SHA2_HEX(command_text) AS command_text_hash,
        SHA2_HEX(environment_name) AS cloud_environment_name_hash,
        SHA2_HEX(job_name) AS cloud_job_name_hash,
        SHA2_HEX(REPLACE(schedule_name, '-', '_')) AS cloud_schedule_name_hash,
        SPLIT_PART(
            "TENANT_RESOURCE_KEY::PROJECT_ID", '::', 1 -- noqa: RF05
        ) AS tenant_resource_key,
        SPLIT_PART(
            "TENANT_RESOURCE_KEY::PROJECT_ID", '::', 2 -- noqa: RF05
        ) AS cloud_project_id
    FROM source
    WHERE row_num = 1
    AND ecs_task_status = 'STOPPED'
    and started_ts IS NOT NULL

)

SELECT *
FROM renamed
