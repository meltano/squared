-- Only match if a project has a single org for now
WITH base AS (

    SELECT
        ip_address_dim.org_name,
        cli_executions_base.project_id
    FROM {{ ref('cli_executions_base') }}
    LEFT JOIN {{ ref('ip_address_dim') }}
        ON cli_executions_base.ip_address_hash = ip_address_dim.ip_address_hash
    WHERE ip_address_dim.org_name IS NOT NULL

),

single_org_projects AS (

    SELECT
        project_id,
        COUNT(DISTINCT org_name) AS org_count
    FROM base
    GROUP BY 1 HAVING org_count = 1

)

SELECT DISTINCT
    base.org_name,
    base.project_id
FROM base
INNER JOIN single_org_projects
    ON base.project_id = single_org_projects.project_id
