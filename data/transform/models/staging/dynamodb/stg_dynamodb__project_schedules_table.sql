WITH source AS (

    SELECT
        *,
        SPLIT_PART(
            "DEPLOYMENT_NAME::SCHEDULE_NAME", '::', 1 -- noqa: RF05
        ) AS cloud_deployment_name,
        REPLACE(
            SPLIT_PART(
                "DEPLOYMENT_NAME::SCHEDULE_NAME", -- noqa: RF05
                '::',
                2
            ), '-', '_'
        ) AS cloud_schedule_name,
        SPLIT_PART(
            "TENANT_RESOURCE_KEY::PROJECT_ID", '::', 1 -- noqa: RF05
        ) AS tenant_resource_key,
        SPLIT_PART(
            "TENANT_RESOURCE_KEY::PROJECT_ID", '::', 2 -- noqa: RF05
        ) AS cloud_project_id
    FROM {{ source('tap_dynamodb', 'project_schedules_table') }}
),

clean_source AS (
    SELECT
        *,
        {{ dbt_utils.surrogate_key(
            ['tenant_resource_key', 'cloud_project_id', 'cloud_deployment_name', 'cloud_schedule_name']
        ) }} AS schedule_surrogate_key,
        ROW_NUMBER() OVER (
            PARTITION BY schedule_surrogate_key
            ORDER BY CAST(_sdc_batched_at AS TIMESTAMP_NTZ) DESC
        ) AS row_num
    FROM source
),

renamed AS (

    SELECT
        schedule_surrogate_key,
        interval,
        enabled AS is_enabled,
        tenant_resource_key,
        cloud_project_id,
        SHA2_HEX(cloud_deployment_name) AS cloud_deployment_name_hash,
        SHA2_HEX(cloud_schedule_name) AS cloud_schedule_name_hash,
        eventbridge_name
    FROM clean_source
    WHERE row_num = 1

)

SELECT *
FROM renamed
