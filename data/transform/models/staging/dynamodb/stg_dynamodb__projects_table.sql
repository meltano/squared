WITH source AS (

    SELECT
        *,
        {{ dbt_utils.surrogate_key(
            ['tenant_resource_key','project_id']
        ) }} AS project_surrogate_key,
        ROW_NUMBER() OVER (
            PARTITION BY project_surrogate_key
            ORDER BY CAST(_sdc_batched_at AS TIMESTAMP_NTZ) DESC
        ) AS row_num
    FROM {{ source('tap_dynamodb', 'projects_table') }}
),

renamed AS (

    SELECT
        project_surrogate_key,
        project_id AS cloud_project_id,
        project_name,
        tenant_resource_key,
        SHA2_HEX(git_repository) AS git_repository_hash,
        SHA2_HEX(project_root_path) AS project_root_path_hash
    FROM source
    WHERE row_num = 1

)

SELECT *
FROM renamed
