WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY execution_id
            ORDER BY _sdc_batched_at::TIMESTAMP_TZ DESC
        ) AS row_num
    FROM {{ source('tap_dynamodb', 'workload_metadata_table') }}
),

renamed AS (

    SELECT
        source.ecs_task_status,
        NULLIF(source.end_time, 'N/A')::TIMESTAMP_TZ AS end_time_ts,
        source.execution_id AS cloud_execution_id,
        NULLIF(source.exit_code, 'N/A')::INT AS cloud_exit_code,
        NULLIF(source.start_time, 'N/A')::TIMESTAMP_TZ AS start_time_ts,
        source.ttl::INT AS cloud_run_ttl,
        SHA2_HEX(source.command_text) AS command_text_hash,
        SHA2_HEX(source.environment_name) AS cloud_environment_name_hash,
        SHA2_HEX(source.job_name) AS cloud_job_name_hash,
        SHA2_HEX(source.schedule_name) AS cloud_schedule_name_hash,
        SPLIT_PART(
            source."TENANT_RESOURCE_KEY::PROJECT_ID", '::', 1 -- noqa: RF05
        ) AS tenant_resource_key,
        SPLIT_PART(
            source."TENANT_RESOURCE_KEY::PROJECT_ID", '::', 2 -- noqa: RF05
        ) AS cloud_project_id
    FROM source
    WHERE source.row_num = 1

)

SELECT *
FROM renamed
