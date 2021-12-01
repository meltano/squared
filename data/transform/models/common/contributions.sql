WITH all_contributions AS (
    SELECT
        project_id,
        created_at,
        author_id,
        'merge_request' AS contribution_type,
        merge_request_id AS contribution_id,
        comment_count,
        COALESCE((merged_at IS NOT NULL OR closed_at IS NOT NULL),
            FALSE) AS is_completed
    FROM {{ ref('stg_gitlab__merge_requests') }}

    UNION ALL

    SELECT
        project_id,
        created_at,
        author_id,
        'issue' AS contribution_type,
        issue_id AS contribution_id,
        comment_count,
        COALESCE((closed_at IS NOT NULL), FALSE) AS is_completed
    FROM {{ ref('stg_gitlab__issues') }}
),

combine AS (
    SELECT
        all_contributions.*,
        stg_gitlab__projects.project_name,
        (
            team_gitlab_ids.user_id IS NOT NULL
            AND all_contributions.created_at >= CAST(
                team_gitlab_ids.start_date AS DATE
            )
        ) AS is_team_contribution

    FROM all_contributions
    LEFT JOIN
        {{ ref('stg_gitlab__projects') }} ON
            all_contributions.project_id = stg_gitlab__projects.project_id
    LEFT JOIN
        {{ ref('team_gitlab_ids') }} ON
            all_contributions.author_id = CAST(
                team_gitlab_ids.user_id AS VARCHAR
            )
)

SELECT * FROM combine
