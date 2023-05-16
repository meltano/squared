SELECT
    cloud_executions_base.*,
    cloud_org_dim.org_name
FROM {{ ref('cloud_executions_base') }}
LEFT JOIN {{ ref('cloud_org_dim') }}
    ON
        cloud_executions_base.tenant_resource_key
        = cloud_org_dim.tenant_resource_key
