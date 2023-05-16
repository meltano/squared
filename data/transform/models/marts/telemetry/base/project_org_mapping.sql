-- Only match if a project has a single org for now
WITH base AS (

    SELECT
        ip_address_dim.org_name,
        ip_address_dim.org_domain,
        cli_executions_base.project_id
    FROM {{ ref('cli_executions_base') }}
    LEFT JOIN {{ ref('ip_address_dim') }}
        ON cli_executions_base.ip_address_hash = ip_address_dim.ip_address_hash
    LEFT JOIN {{ ref('internal_data', 'project_org_manual') }}
        ON cli_executions_base.project_id = project_org_manual.project_id
    WHERE
        ip_address_dim.org_name IS NOT NULL
        -- Exclude manual override of Leadmagic
        AND project_org_manual.project_id IS NULL

),

single_org_projects AS (

    SELECT
        project_id,
        COUNT(DISTINCT org_name) AS org_count,
        COUNT(DISTINCT org_domain) AS org_domain_count
    FROM base
    GROUP BY 1
    HAVING org_count = 1 AND org_domain_count = 1

)

SELECT DISTINCT
    base.org_name,
    base.org_domain,
    base.project_id,
    'LEADMAGIC' AS org_source
FROM base
INNER JOIN single_org_projects
    ON base.project_id = single_org_projects.project_id

UNION ALL

SELECT DISTINCT
    org_name,
    org_domain,
    project_id,
    'MANUAL' AS org_source
FROM {{ ref('internal_data', 'project_org_manual') }}
