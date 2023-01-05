-- Only match if a project has a single org for now
SELECT
    cli_executions_base.project_id,
    ip_org_mapping.org_name
FROM {{ ref('cli_executions_base') }}
LEFT JOIN {{ ref('internal_data', 'ip_org_mapping') }}
    ON cli_executions_base.ip_address_hash = MD5(ip_org_mapping.ip_address)
WHERE ip_org_mapping.org_name IS NOT NULL
GROUP BY 1, 2 HAVING COUNT(*) = 1
