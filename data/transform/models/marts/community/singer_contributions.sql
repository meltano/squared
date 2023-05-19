SELECT
    'issue' AS contribution_type,
    stg_github_search__issues.organization_name,
    stg_github_search__issues.repo_name,
    stg_github_search__issues.html_url,
    stg_github_search__issues.last_updated_ts,
    stg_github_search__issues.created_at_ts,
    stg_github_search__issues.closed_at_ts,
    NULL AS pr_merged_at_ts,
    (
        team_github_ids.user_id IS NOT NULL
        AND stg_github_search__issues.created_at_ts
        >= team_github_ids.start_date
    ) AS is_team_contribution,
    stg_github_search__issues.is_bot_user,
    stg_github_search__issues.title,
    stg_github_search__issues.state,
    singer_repo_dim.is_fork,
    COALESCE(stg_meltanohub__plugins.is_default, FALSE) AS is_hub_default,
    FALSE AS is_draft_pr,
    stg_github_search__issues.author_username,
    stg_github_search__issues.assignee_username,
    stg_github_search__issues.comment_count,
    stg_github_search__issues.reactions_count,
    singer_repo_dim.repo_url,
    singer_repo_dim.num_open_issues,
    singer_repo_dim.is_archived,
    singer_repo_dim.connector_type,
    singer_repo_dim.created_at_ts AS repo_created_at_ts,
    singer_repo_dim.last_updated_ts AS repo_updated_at_ts,
    singer_repo_dim.last_push_ts AS repo_last_push_ts,
    COALESCE(
        singer_repo_dim.created_at_ts IS NULL,
        FALSE
    ) AS is_ownership_transferred,
    COALESCE(stg_meltanohub__plugins.repo IS NOT NULL, FALSE) AS is_hub_listed
FROM {{ ref('stg_github_search__issues') }}
INNER JOIN {{ ref('singer_repo_dim') }}
    ON
        LOWER(
            stg_github_search__issues.organization_name
        ) = LOWER(
            singer_repo_dim.repo_namespace
        ) AND LOWER(
            stg_github_search__issues.repo_name
        ) = LOWER(singer_repo_dim.repo_name)
LEFT JOIN {{ ref('stg_meltanohub__plugins') }}
    ON
        LOWER(
            stg_meltanohub__plugins.repo
        ) = LOWER(singer_repo_dim.repo_url)
LEFT JOIN
    {{ ref('team_github_ids') }} ON
    stg_github_search__issues.author_id = team_github_ids.user_id

UNION ALL

SELECT
    'pull_request' AS contribution_type,
    stg_github_search__pull_requests.organization_name,
    stg_github_search__pull_requests.repo_name,
    stg_github_search__pull_requests.html_url,
    stg_github_search__pull_requests.last_updated_ts,
    stg_github_search__pull_requests.created_at_ts,
    stg_github_search__pull_requests.closed_at_ts,
    stg_github_search__pull_requests.merged_at_ts AS pr_merged_at_ts,
    (
        team_github_ids.user_id IS NOT NULL
        AND stg_github_search__pull_requests.created_at_ts
        >= team_github_ids.start_date
    ) AS is_team_contribution,
    stg_github_search__pull_requests.is_bot_user,
    stg_github_search__pull_requests.title,
    stg_github_search__pull_requests.state,
    singer_repo_dim.is_fork,
    COALESCE(stg_meltanohub__plugins.is_default, FALSE) AS is_hub_default,
    COALESCE(stg_github_search__pull_requests.is_draft, FALSE) AS is_draft_pr,
    stg_github_search__pull_requests.author_username,
    stg_github_search__pull_requests.assignee_username,
    stg_github_search__pull_requests.comment_count,
    stg_github_search__pull_requests.reactions_count,
    singer_repo_dim.repo_url,
    singer_repo_dim.num_open_issues,
    singer_repo_dim.is_archived,
    singer_repo_dim.connector_type,
    singer_repo_dim.created_at_ts AS repo_created_at_ts,
    singer_repo_dim.last_updated_ts AS repo_updated_at_ts,
    singer_repo_dim.last_push_ts AS repo_last_push_ts,
    COALESCE(
        singer_repo_dim.created_at_ts IS NULL,
        FALSE
    ) AS is_ownership_transferred,
    COALESCE(stg_meltanohub__plugins.repo IS NOT NULL, FALSE) AS is_hub_listed
FROM {{ ref('stg_github_search__pull_requests') }}
INNER JOIN {{ ref('singer_repo_dim') }}
    ON
        LOWER(
            stg_github_search__pull_requests.organization_name
        ) = LOWER(
            singer_repo_dim.repo_namespace
        ) AND LOWER(
            stg_github_search__pull_requests.repo_name
        ) = LOWER(singer_repo_dim.repo_name)
LEFT JOIN {{ ref('stg_meltanohub__plugins') }}
    ON
        LOWER(
            stg_meltanohub__plugins.repo
        ) = LOWER(singer_repo_dim.repo_url)
LEFT JOIN
    {{ ref('team_github_ids') }} ON
    stg_github_search__pull_requests.author_id = team_github_ids.user_id

UNION ALL

SELECT
    'issue' AS contribution_type,
    stg_gitlab__issues.project_namespace,
    stg_gitlab__issues.project_name,
    stg_gitlab__issues.html_url,
    stg_gitlab__issues.updated_at_ts,
    stg_gitlab__issues.created_at_ts,
    stg_gitlab__issues.closed_at_ts,
    NULL AS pr_merged_at_ts,
    (
        team_gitlab_ids.user_id IS NOT NULL
        AND stg_gitlab__issues.created_at_ts
        >= team_gitlab_ids.start_date
    ) AS is_team_contribution,
    stg_gitlab__issues.is_bot_user,
    stg_gitlab__issues.title,
    stg_gitlab__issues.state,
    singer_repo_dim.is_fork,
    COALESCE(stg_meltanohub__plugins.is_default, FALSE) AS is_hub_default,
    FALSE AS is_draft_pr,
    stg_gitlab__issues.author_username,
    stg_gitlab__issues.assignee_id AS assignee_username,
    stg_gitlab__issues.comment_count,
    (stg_gitlab__issues.upvotes + stg_gitlab__issues.downvotes) AS reactions_count,
    singer_repo_dim.repo_url,
    singer_repo_dim.num_open_issues,
    singer_repo_dim.is_archived,
    singer_repo_dim.connector_type,
    singer_repo_dim.created_at_ts AS repo_created_at_ts,
    singer_repo_dim.last_updated_ts AS repo_updated_at_ts,
    singer_repo_dim.last_push_ts AS repo_last_push_ts,
    COALESCE(
        singer_repo_dim.created_at_ts IS NULL,
        FALSE
    ) AS is_ownership_transferred,
    COALESCE(stg_meltanohub__plugins.repo IS NOT NULL, FALSE) AS is_hub_listed
FROM {{ ref('stg_gitlab__issues') }}
INNER JOIN {{ ref('singer_repo_dim') }}
    ON
        LOWER(
            stg_gitlab__issues.project_namespace
        ) = LOWER(
            singer_repo_dim.repo_namespace
        ) AND LOWER(
            stg_gitlab__issues.project_name
        ) = LOWER(singer_repo_dim.repo_name)
LEFT JOIN {{ ref('stg_meltanohub__plugins') }}
    ON
        LOWER(
            stg_meltanohub__plugins.repo
        ) = LOWER(singer_repo_dim.repo_url)
LEFT JOIN
    {{ ref('team_gitlab_ids') }} ON
    stg_gitlab__issues.author_id = team_gitlab_ids.user_id

UNION ALL

SELECT
    'pull_request' AS contribution_type,
    stg_gitlab__merge_requests.project_namespace,
    stg_gitlab__merge_requests.project_name,
    stg_gitlab__merge_requests.html_url,
    stg_gitlab__merge_requests.updated_at_ts,
    stg_gitlab__merge_requests.created_at_ts,
    stg_gitlab__merge_requests.closed_at_ts,
    stg_gitlab__merge_requests.merged_at_ts AS pr_merged_at_ts,
    (
        team_gitlab_ids.user_id IS NOT NULL
        AND stg_gitlab__merge_requests.created_at_ts
        >= team_gitlab_ids.start_date
    ) AS is_team_contribution,
    stg_gitlab__merge_requests.is_bot_user,
    stg_gitlab__merge_requests.title,
    stg_gitlab__merge_requests.state,
    singer_repo_dim.is_fork,
    COALESCE(stg_meltanohub__plugins.is_default, FALSE) AS is_hub_default,
    COALESCE(stg_gitlab__merge_requests.is_work_in_progress, FALSE) AS is_draft_pr,
    stg_gitlab__merge_requests.author_username,
    stg_gitlab__merge_requests.assignee_id AS assignee_username,
    stg_gitlab__merge_requests.comment_count,
    (stg_gitlab__merge_requests.upvotes + stg_gitlab__merge_requests.downvotes) AS reactions_count,
    singer_repo_dim.repo_url,
    singer_repo_dim.num_open_issues,
    singer_repo_dim.is_archived,
    singer_repo_dim.connector_type,
    singer_repo_dim.created_at_ts AS repo_created_at_ts,
    singer_repo_dim.last_updated_ts AS repo_updated_at_ts,
    singer_repo_dim.last_push_ts AS repo_last_push_ts,
    COALESCE(
        singer_repo_dim.created_at_ts IS NULL,
        FALSE
    ) AS is_ownership_transferred,
    COALESCE(stg_meltanohub__plugins.repo IS NOT NULL, FALSE) AS is_hub_listed
FROM {{ ref('stg_gitlab__merge_requests') }}
INNER JOIN {{ ref('singer_repo_dim') }}
    ON
        LOWER(
            stg_gitlab__merge_requests.project_namespace
        ) = LOWER(
            singer_repo_dim.repo_namespace
        ) AND LOWER(
            stg_gitlab__merge_requests.project_name
        ) = LOWER(singer_repo_dim.repo_name)
LEFT JOIN {{ ref('stg_meltanohub__plugins') }}
    ON
        LOWER(
            stg_meltanohub__plugins.repo
        ) = LOWER(singer_repo_dim.repo_url)
LEFT JOIN
    {{ ref('team_gitlab_ids') }} ON
    stg_gitlab__merge_requests.author_id = team_gitlab_ids.user_id
