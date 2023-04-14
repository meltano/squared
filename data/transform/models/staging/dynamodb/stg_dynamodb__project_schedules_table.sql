WITH source AS (

    SELECT
        *,
        {{ dbt_utils.surrogate_key(
            ['"TENANT_RESOURCE_KEY::PROJECT_ID"', '"DEPLOYMENT_NAME::SCHEDULE_NAME"']
        ) }} AS schedule_surrogate_key,
        ROW_NUMBER() OVER (
            PARTITION BY schedule_surrogate_key
            ORDER BY CAST (_sdc_batched_at AS TIMESTAMP_TZ) DESC
        ) AS row_num
    FROM {{ source('tap_dynamodb', 'project_schedules_table') }}
),

renamed AS (

    SELECT
        source.schedule_surrogate_key,
        source.interval,
        source.enabled AS is_enabled,
        SHA2_HEX(
            SPLIT_PART(
                source."DEPLOYMENT_NAME::SCHEDULE_NAME", '::', 1 -- noqa: RF05
            )
        ) AS cloud_deployment_name_hash,
        SHA2_HEX(
            SPLIT_PART(
                source."DEPLOYMENT_NAME::SCHEDULE_NAME", '::', 2 -- noqa: RF05
            )
        ) AS cloud_schedule_name_hash,
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
