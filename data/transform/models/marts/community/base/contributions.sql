
{{ config(materialized='table') }}

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

github_all AS (
    SELECT
        repo_name,
        organization_name,
        'github' AS platform,
        created_at_ts,
        author_id,
        'merge_request' AS contribution_type,
        pull_request_id AS contribution_id,
        comment_count,
        COALESCE((merged_at_ts IS NOT NULL OR closed_at_ts IS NOT NULL),
            FALSE) AS is_completed
    FROM {{ ref('stg_github__pull_requests') }}

    UNION ALL

    SELECT
        repo_name,
        organization_name,
        'github' AS platform,
        created_at_ts,
        author_id,
        'issue' AS contribution_type,
        issue_id AS contribution_id,
        comment_count,
        COALESCE((closed_at_ts IS NOT NULL), FALSE) AS is_completed
    FROM {{ ref('stg_github__issues') }}

),

gitlab_combined AS (
    SELECT
        gitlab_all.project_id,
        stg_gitlab__projects.repo_full_name,
        gitlab_all.platform,
        gitlab_all.created_at_ts,
        username_mapping.user_surrogate_key,
        gitlab_all.contribution_type,
        gitlab_all.contribution_id,
        gitlab_all.comment_count,
        gitlab_all.is_completed,
        (
            team_gitlab_ids.user_id IS NOT NULL
            AND gitlab_all.created_at_ts >= team_gitlab_ids.start_date
        ) AS is_team_contribution
    FROM gitlab_all
    LEFT JOIN
        {{ ref('team_gitlab_ids') }} ON
            gitlab_all.author_id = team_gitlab_ids.user_id
    LEFT JOIN
        {{ ref('stg_gitlab__projects') }} ON
            gitlab_all.project_id = stg_gitlab__projects.project_id
    LEFT JOIN
        {{ ref('username_mapping') }} ON
            gitlab_all.author_id = username_mapping.gitlab_author_id
    WHERE stg_gitlab__projects.visibility = 'public'
),

github_combined AS (
    SELECT
        stg_github__repositories.repo_id AS project_id,
        stg_github__repositories.repo_full_name,
        github_all.platform,
        github_all.created_at_ts,
        username_mapping.user_surrogate_key,
        github_all.contribution_type,
        github_all.contribution_id,
        github_all.comment_count,
        github_all.is_completed,
        (
            team_github_ids.user_id IS NOT NULL
            AND github_all.created_at_ts >= team_github_ids.start_date
        ) AS is_team_contribution
    FROM github_all
    LEFT JOIN
        {{ ref('team_github_ids') }} ON
            github_all.author_id = team_github_ids.user_id
    LEFT JOIN {{ ref('stg_github__repositories') }} ON
        github_all.organization_name = stg_github__repositories.organization_name -- noqa: L016
        AND github_all.repo_name = stg_github__repositories.repo_name
    LEFT JOIN
        {{ ref('username_mapping') }} ON
            github_all.author_id = username_mapping.github_author_id
    WHERE stg_github__repositories.visibility = 'public'
)

SELECT * FROM gitlab_combined
UNION ALL
SELECT * FROM github_combined
