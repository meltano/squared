WITH credits AS (
    SELECT
        tenant_resource_key,
        SUM(credits_allocated) AS credits_allocated,
        SUM(spend_usd) AS spend_usd
    FROM {{ ref('cloud_credits') }}
    WHERE notes != 'trial'
    GROUP BY 1

),

usage AS (

    SELECT
        tenant_resource_key,
        SUM(credits_used_estimate) AS credits_used_estimate,
        COUNT(DISTINCT cloud_project_id) AS cloud_projects,
        MAX(is_currently_active) AS is_currently_active,
        -- TODO: this is not distinct across projects
        COUNT(
            DISTINCT cloud_schedule_name_hash
        ) AS cloud_schedules,
        COUNT(
            DISTINCT CASE
                WHEN schedule_is_enabled = TRUE THEN cloud_schedule_name_hash
            END
        ) AS cloud_schedules_enabled,
        COUNT(
            DISTINCT CASE
                WHEN
                    schedule_is_enabled = TRUE AND 1 = 1
                    THEN cloud_schedule_name_hash
            END
        ) AS cloud_schedules_healthy
    FROM {{ ref('cloud_executions_base') }}
    GROUP BY 1
)

SELECT
    cloud_orgs.tenant_resource_key,
    cloud_orgs.org_name,
    COALESCE(credits.credits_allocated, 0) AS credits_allocated,
    COALESCE(credits.spend_usd, 0) AS spend_usd,
    COALESCE(usage.credits_used_estimate, 0) AS credits_used_estimate,
    (
        COALESCE(credits.credits_allocated, 0)
        - COALESCE(usage.credits_used_estimate, 0)
    ) AS credits_balance_estimate,
    COALESCE(usage.cloud_projects, 0) AS cloud_projects,
    COALESCE(usage.is_currently_active, FALSE) AS is_currently_active,
    COALESCE(usage.cloud_schedules, 0) AS cloud_schedules,
    COALESCE(usage.cloud_schedules_enabled, 0) AS cloud_schedules_enabled,
    COALESCE(usage.cloud_schedules_healthy, 0) AS cloud_schedules_healthy
FROM {{ ref('cloud_orgs') }}
LEFT JOIN credits
    ON cloud_orgs.tenant_resource_key = credits.tenant_resource_key
LEFT JOIN usage
    ON cloud_orgs.tenant_resource_key = usage.tenant_resource_key
