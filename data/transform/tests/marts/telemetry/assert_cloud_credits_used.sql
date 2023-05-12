WITH cloud_execs AS (
    SELECT
        org_name,
        COALESCE(SUM(credits_used_estimate), 0) AS sum_credits
    FROM {{ ref('fact_cloud_executions') }}
    GROUP BY 1
)

SELECT
    cloud_org_dim.tenant_resource_key,
    cloud_org_dim.org_name,
    cloud_org_dim.credits_used_estimate,
    cloud_execs.sum_credits
FROM cloud_execs
LEFT JOIN
    {{ ref('cloud_org_dim') }}
    ON cloud_org_dim.org_name = cloud_execs.org_name
WHERE COALESCE(sum_credits != credits_used_estimate, true)
