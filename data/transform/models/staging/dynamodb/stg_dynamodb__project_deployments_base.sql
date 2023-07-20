WITH source AS (

    SELECT
        *,
        SPLIT_PART(
            "TENANT_RESOURCE_KEY::PROJECT_ID", '::', 1 -- noqa: RF05
        ) AS tenant_resource_key,
        SPLIT_PART(
            "TENANT_RESOURCE_KEY::PROJECT_ID", '::', 2 -- noqa: RF05
        ) AS cloud_project_id
    FROM {{ source('tap_dynamodb', 'project_deployments_table') }}
),

clean_source AS (
    SELECT
        *,
        {{ dbt_utils.surrogate_key(
            ['tenant_resource_key', 'cloud_project_id', 'deployment_name']
        ) }} AS deployment_surrogate_key,
        ROW_NUMBER() OVER (
            PARTITION BY deployment_surrogate_key
            ORDER BY CAST(_sdc_batched_at AS TIMESTAMP_NTZ) DESC
        ) AS row_num
    FROM source
),

renamed AS (

    SELECT
        deployment_surrogate_key,
        tenant_resource_key,
        cloud_project_id,
        git_rev,
        git_rev_hash,
        schedules AS schedules_obj,
        SHA2_HEX(deployment_name) AS cloud_deployment_name_hash,
        SHA2_HEX(environment_name) AS cloud_environment_name_hash,
        CAST(
            last_deployed_timestamp AS TIMESTAMP_NTZ
        ) AS last_deployed_timestamp
    FROM clean_source
    WHERE row_num = 1

)

SELECT *
FROM renamed
