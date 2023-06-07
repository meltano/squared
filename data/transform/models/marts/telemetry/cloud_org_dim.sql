WITH credits AS (

    SELECT
        tenant_resource_key,
        SUM(credits_allocated) AS credits_allocated,
        SUM(spend_usd) AS spend_usd
    FROM {{ ref('cloud_credits') }}
    WHERE notes != 'trial'
    GROUP BY 1

),

schedules AS (

    SELECT
        tenant_resource_key,
        cloud_project_id,
        cloud_schedule_name_hash,
        cloud_exit_code AS latest_exit_code
    FROM {{ ref('cloud_executions_base') }}
    QUALIFY
        ROW_NUMBER() OVER (
            PARTITION BY
                tenant_resource_key, cloud_project_id, cloud_schedule_name_hash
            ORDER BY started_ts DESC
        ) = 1

),

usage AS (

    SELECT
        cloud_executions_base.tenant_resource_key,
        SUM(
            cloud_executions_base.credits_used_estimate
        ) AS credits_used_estimate,
        COUNT(
            DISTINCT cloud_executions_base.cloud_project_id
        ) AS cloud_projects,
        MAX(cloud_executions_base.is_currently_active) AS is_currently_active,
        -- TODO: this is not distinct across projects
        COUNT(
            DISTINCT cloud_executions_base.cloud_schedule_name_hash
        ) AS cloud_schedules,
        COUNT(
            DISTINCT CASE
                WHEN
                    cloud_executions_base.schedule_is_enabled = TRUE
                    THEN cloud_executions_base.cloud_schedule_name_hash
            END
        ) AS cloud_schedules_enabled,
        COUNT(
            DISTINCT CASE
                WHEN
                    cloud_executions_base.schedule_is_enabled = TRUE
                    AND schedules.latest_exit_code = 0
                    THEN cloud_executions_base.cloud_schedule_name_hash
            END
        ) AS cloud_schedules_healthy
    FROM {{ ref('cloud_executions_base') }}
    LEFT JOIN schedules
        ON
            cloud_executions_base.tenant_resource_key
            = schedules.tenant_resource_key
            AND cloud_executions_base.cloud_project_id
            = schedules.cloud_project_id
            AND cloud_executions_base.cloud_schedule_name_hash
            = schedules.cloud_schedule_name_hash
    GROUP BY 1

)

SELECT
    stg_dynamodb__organizations_table.tenant_resource_key,
    stg_dynamodb__organizations_table.org_name,
    stg_dynamodb__organizations_table.org_display_name,
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
FROM {{ ref('stg_dynamodb__organizations_table') }}
LEFT JOIN credits
    ON
        stg_dynamodb__organizations_table.tenant_resource_key
        = credits.tenant_resource_key
LEFT JOIN usage
    ON
        stg_dynamodb__organizations_table.tenant_resource_key
        = usage.tenant_resource_key
