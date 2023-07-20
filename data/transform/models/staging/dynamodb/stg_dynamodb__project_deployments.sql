SELECT
    deployment_surrogate_key,
    tenant_resource_key,
    cloud_project_id,
    git_rev,
    git_rev_hash,
    cloud_deployment_name_hash,
    cloud_environment_name_hash,
    last_deployed_timestamp
FROM {{ ref('stg_dynamodb__project_deployments_base') }}
