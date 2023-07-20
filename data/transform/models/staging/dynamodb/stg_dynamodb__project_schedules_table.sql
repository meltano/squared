SELECT
    {{ dbt_utils.surrogate_key(
        [
            'stg_dynamodb__project_deployments_base.deployment_surrogate_key',
            'CAST(schedule_elem.value:schedule_name AS STRING)'
        ]
    ) }} AS schedule_surrogate_key,
    stg_dynamodb__project_deployments_base.deployment_surrogate_key,
    CAST(schedule_elem.value:interval AS STRING) AS schedule_interval,
    CAST(schedule_elem.value:enabled AS BOOLEAN) AS schedule_is_enabled,
    stg_dynamodb__project_deployments_base.tenant_resource_key,
    stg_dynamodb__project_deployments_base.cloud_project_id,
    CAST(schedule_elem.value:eventbridge_name AS STRING) AS eventbridge_name,
    stg_dynamodb__project_deployments_base.cloud_deployment_name_hash,
    SHA2_HEX(
        CAST(schedule_elem.value:schedule_name AS STRING)
    ) AS cloud_schedule_name_hash
FROM {{ ref('stg_dynamodb__project_deployments_base') }},
    LATERAL FLATTEN(input => schedules_obj) AS schedule_elem
