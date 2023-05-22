{{ config(materialized='view') }}

WITH gitlab_all AS (
    SELECT
        project_id,
        'gitlab' AS platform,
        created_at_ts,
        merged_at_ts,
        closed_at_ts,
        'merge_request' AS contribution_type,
        merge_request_id AS contribution_id,
        merge_request_internal_id AS contribution_number,
        author_id,
        author_username,
        assignee_id,
        state,
        is_work_in_progress AS is_draft,
        comment_count,
        COALESCE(
            (merged_at_ts IS NOT NULL OR closed_at_ts IS NOT NULL),
            FALSE
        ) AS is_completed
    FROM {{ ref('stg_gitlab__merge_requests') }}
    WHERE project_namespace = 'meltano'

    UNION ALL

    SELECT
        project_id,
        'gitlab' AS platform,
        created_at_ts,
        NULL AS merged_at_ts,
        closed_at_ts,
        'issue' AS contribution_type,
        issue_id AS contribution_id,
        issue_internal_id AS contribution_number,
        author_id,
        author_username,
        assignee_id,
        state,
        NULL AS is_draft,
        comment_count,
        COALESCE((closed_at_ts IS NOT NULL), FALSE) AS is_completed
    FROM {{ ref('stg_gitlab__issues') }}
    WHERE project_namespace = 'meltano'

),

github_all AS (
    SELECT
        repo_name,
        organization_name,
        'github' AS platform,
        created_at_ts,
        merged_at_ts,
        closed_at_ts,
        'pull_request' AS contribution_type,
        pull_request_id AS contribution_id,
        pr_number AS contribution_number,
        author_id,
        author_username,
        assignee_username,
        is_bot_user,
        state,
        is_draft,
        comment_count,
        COALESCE(
            (merged_at_ts IS NOT NULL OR closed_at_ts IS NOT NULL),
            FALSE
        ) AS is_completed
    FROM {{ ref('stg_github__pull_requests') }}

    UNION ALL

    SELECT
        repo_name,
        organization_name,
        'github' AS platform,
        created_at_ts,
        NULL AS merged_at_ts,
        closed_at_ts,
        'issue' AS contribution_type,
        issue_id AS contribution_id,
        issue_number AS contribution_number,
        author_id,
        author_username,
        assignee_username,
        is_bot_user,
        state,
        NULL AS is_draft,
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
        gitlab_all.merged_at_ts,
        gitlab_all.closed_at_ts,
        gitlab_all.contribution_type,
        gitlab_all.contribution_id,
        gitlab_all.contribution_number,
        gitlab_all.author_id,
        gitlab_all.author_username,
        username_mapping.user_surrogate_key,
        gitlab_all.state,
        gitlab_all.is_draft,
        gitlab_all.comment_count,
        gitlab_all.is_completed,
        CASE
            WHEN
                gitlab_all.contribution_type = 'issue'
                THEN
                    'https://gitlab.com/'
                    || stg_gitlab__projects.repo_full_name
                    || '/-/issues/' || gitlab_all.contribution_number::STRING
            ELSE
                'https://gitlab.com/' || stg_gitlab__projects.repo_full_name
                || '/-/merge_requests/'
                || gitlab_all.contribution_number::STRING
        END AS contribution_url,
        (
            team_gitlab_ids.user_id IS NOT NULL
            AND gitlab_all.created_at_ts
            BETWEEN team_gitlab_ids.start_date AND COALESCE(
                team_gitlab_ids.end_date, '2100-01-01'
            )
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
    WHERE
        stg_gitlab__projects.project_namespace = 'meltano'
        AND stg_gitlab__projects.visibility = 'public'
),

github_combined AS (
    SELECT
        stg_github__repositories.repo_id AS project_id,
        stg_github__repositories.repo_full_name,
        github_all.platform,
        github_all.created_at_ts,
        github_all.merged_at_ts,
        github_all.closed_at_ts,
        github_all.contribution_type,
        github_all.contribution_id,
        github_all.contribution_number,
        github_all.author_id,
        github_all.author_username,
        username_mapping.user_surrogate_key,
        github_all.state,
        github_all.is_draft,
        github_all.comment_count,
        github_all.is_completed,
        CASE
            WHEN
                github_all.contribution_type = 'issue'
                THEN
                    stg_github__repositories.html_url || '/issues/'
                    || github_all.contribution_number::STRING
            ELSE
                stg_github__repositories.html_url || '/pull/'
                || github_all.contribution_number::STRING
        END AS contribution_url,
        (
            team_github_ids.user_id IS NOT NULL
            AND github_all.created_at_ts
            BETWEEN team_github_ids.start_date AND COALESCE(
                team_github_ids.end_date, '2100-01-01'
            )
        ) AS is_team_contribution
    FROM github_all
    LEFT JOIN
        {{ ref('team_github_ids') }} ON
        github_all.author_id = team_github_ids.user_id
    LEFT JOIN
        {{ ref('stg_github__repositories') }} ON
        github_all.organization_name = stg_github__repositories.organization_name -- noqa: L016
        AND github_all.repo_name = stg_github__repositories.repo_name
    LEFT JOIN
        {{ ref('username_mapping') }} ON
        github_all.author_id = username_mapping.github_author_id
    WHERE
        stg_github__repositories.visibility = 'public'
        AND github_all.is_bot_user = FALSE
)

SELECT * FROM gitlab_combined
UNION ALL
SELECT * FROM github_combined
