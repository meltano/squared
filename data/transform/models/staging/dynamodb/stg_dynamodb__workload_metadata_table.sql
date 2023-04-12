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
        ecs_task_status,
        NULLIF(end_time, 'N/A')::TIMESTAMP_TZ AS end_time_ts,
        execution_id AS cloud_execution_id,
        NULLIF(exit_code, 'N/A')::INT AS cloud_exit_code,
        NULLIF(start_time, 'N/A')::TIMESTAMP_TZ AS start_time_ts,
        ttl::INT AS cloud_run_ttl,
        SHA2_HEX(command_text) AS command_text_hash,
        COALESCE(
            hash_lookup.unhashed_value,
            SHA2_HEX(source.environment_name)
        ) AS cloud_environment_name,
        SHA2_HEX(job_name) AS cloud_job_name_hash,
        SHA2_HEX(schedule_name) AS cloud_schedule_name_hash,
        SPLIT_PART(
            "TENANT_RESOURCE_KEY::PROJECT_ID", '::', 1
        ) AS surrogate_tenant_resource_key,
        SPLIT_PART(
            "TENANT_RESOURCE_KEY::PROJECT_ID", '::', 2
        ) AS cloud_project_id
    FROM source
    LEFT JOIN {{ ref('hash_lookup') }}
    ON
        SHA2_HEX(source.environment_name) = hash_lookup.hash_value
        AND hash_lookup.category = 'environment'
    WHERE row_num = 1

)

SELECT *
FROM renamed
