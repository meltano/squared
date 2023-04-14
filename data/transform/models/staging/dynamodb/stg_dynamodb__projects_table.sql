WITH source AS (

    SELECT
        *,
        {{ dbt_utils.surrogate_key(
            ['tenant_resource_key','project_id']
        ) }} project_surrogate_key,
        ROW_NUMBER() OVER (
            PARTITION BY project_surrogate_key
            ORDER BY _sdc_batched_at::TIMESTAMP_TZ DESC
        ) AS row_num
    FROM {{ source('tap_dynamodb', 'projects_table') }}
),

renamed AS (

    SELECT
        project_surrogate_key,
        project_id AS cloud_project_id,
        project_name,
        tenant_resource_key
    FROM source
    WHERE source.row_num = 1

)

SELECT *
FROM renamed
