SELECT
    platform,
    repo_full_name,
    contribution_type,
    CAST(created_at_ts AS DATE) AS created_at_date,
    COUNT(DISTINCT contribution_id) AS contributions,
    COUNT(DISTINCT user_surrogate_key) AS authors,
    SUM(comment_count) AS comments
FROM {{ ref('contributions') }}
WHERE is_team_contribution = FALSE
GROUP BY 1, 2, 3, 4
