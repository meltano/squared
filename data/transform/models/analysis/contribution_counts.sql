SELECT
    COUNT(*) AS contribution_count,
    DATE_TRUNC('month', contributions.created_at) AS created_at_month
FROM {{ ref('contributions') }}
WHERE NOT is_team_contribution
GROUP BY 2
ORDER BY 2 DESC
