WITH base AS (
    SELECT
        CAST(created_at_ts AS DATE) AS created_at_date,
        platform,
        project_name,
        contribution_type,
        COUNT(DISTINCT contribution_id) AS contributions,
        COUNT(DISTINCT author_id) AS authors,
        SUM(comment_count) AS comments
    FROM {{ ref('contributions') }}
    WHERE is_team_contribution = FALSE
    GROUP BY 1,2,3,4
)
SELECT
    dim_date.date_day AS created_at_date,
    base.platform,
    base.project_name,
    base.contribution_type,
    base.contributions,
    base.authors,
    base.comments
FROM {{ ref('dim_date') }}
INNER JOIN base ON dim_date.date_day = base.created_at_date