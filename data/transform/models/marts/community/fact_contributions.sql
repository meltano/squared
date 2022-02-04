WITH base AS (
    SELECT
        CAST(created_at_ts AS DATE) AS created_at_date,
        platform,
        project_id,
        contribution_type,
        COUNT(DISTINCT contribution_id) AS contributions,
        COUNT(DISTINCT author_id) AS authors,
        SUM(comment_count) AS comments
    FROM {{ ref('contributions') }}
    GROUP BY 1,2,3,4
)
SELECT
    base.*
FROM {{ ref('dim_date') }}
LEFT JOIN base ON dim_date.date_day = base.created_at_date