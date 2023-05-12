SELECT
    cloud_project_id,
    tenant_resource_key,
    cloud_schedule_name_hash,
    cloud_deployment_name_hash,
    COUNT(*) AS count
FROM {{ ref('stg_dynamodb__project_schedules_table') }}
GROUP BY 1, 2, 3, 4 HAVING COUNT(*) > 1
