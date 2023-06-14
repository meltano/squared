{{
    config(
        enabled=false
    )
}}
-- This will alert us when deployments dont match env names which will
-- break the metadata + project schedules join
-- TODO: refactor joins https://github.com/meltano/squared/issues/643
SELECT *
FROM {{ ref('stg_dynamodb__project_deployments') }}
WHERE cloud_deployment_name_hash != cloud_environment_name_hash
