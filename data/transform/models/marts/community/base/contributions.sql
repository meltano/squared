WITH gitlab_all AS (
    SELECT
        project_id,
        'gitlab' AS platform,
        created_at_ts,
        author_id,
        'merge_request' AS contribution_type,
        merge_request_id AS contribution_id,
        comment_count,
        COALESCE((merged_at_ts IS NOT NULL OR closed_at_ts IS NOT NULL),
            FALSE) AS is_completed
    FROM {{ ref('stg_gitlab__merge_requests') }}

    UNION ALL

    SELECT
        project_id,
        'gitlab' AS platform,
        created_at_ts,
        author_id,
        'issue' AS contribution_type,
        issue_id AS contribution_id,
        comment_count,
        COALESCE((closed_at_ts IS NOT NULL), FALSE) AS is_completed
    FROM {{ ref('stg_gitlab__issues') }}
),
gitlab_combined AS (
    SELECT
        gitlab_all.*,
        stg_gitlab__projects.project_name,
        (
            team_gitlab_ids.user_id IS NOT NULL
            AND gitlab_all.created_at_ts >= CAST(
                team_gitlab_ids.start_date AS DATE
            )
        ) AS is_team_contribution
    FROM gitlab_all
    LEFT JOIN
        {{ ref('team_gitlab_ids') }} ON
            gitlab_all.author_id = CAST(
                team_gitlab_ids.user_id AS VARCHAR
            )
    LEFT JOIN
        {{ ref('stg_gitlab__projects') }} ON
            gitlab_all.project_id = stg_gitlab__projects.project_id
)

SELECT * FROM gitlab_combined