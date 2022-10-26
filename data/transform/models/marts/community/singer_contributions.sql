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
    stg_github_search__repositories.is_fork,
    stg_meltanohub__plugins.is_default AS is_hub_default,
    NULL AS is_draft_pr,
    stg_github_search__issues.author_username,
    stg_github_search__issues.assignee_username,
    stg_github_search__issues.comment_count,
    stg_github_search__issues.reactions_count,
    stg_github_search__repositories.num_open_issues,
    stg_github_search__repositories.visibility,
    stg_github_search__repositories.is_archived,
    stg_github_search__repositories.created_at_ts AS repo_created_at_ts,
    stg_github_search__repositories.last_updated_ts AS repo_updated_at_ts,
    stg_github_search__repositories.last_push_ts AS repo_last_push_ts
FROM {{ ref('stg_github_search__issues') }}
LEFT JOIN {{ ref('stg_github_search__repositories') }}
    ON
        lower(
            stg_github_search__issues.organization_name
        ) = lower(
            stg_github_search__repositories.repo_namespace
        ) AND lower(
            stg_github_search__issues.repo_name
        ) = lower(stg_github_search__repositories.repo_name)
LEFT JOIN {{ ref('stg_meltanohub__plugins') }}
    ON
        lower(
            stg_meltanohub__plugins.repo
        ) = lower(stg_github_search__repositories.repo_url)
LEFT JOIN
    {{ ref('team_github_ids') }} ON
        stg_github_search__issues.author_id = team_github_ids.user_id
WHERE stg_meltanohub__plugins.repo IS NOT NULL

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
    stg_github_search__repositories.is_fork,
    stg_meltanohub__plugins.is_default AS is_hub_default,
    stg_github_search__pull_requests.is_draft AS is_draft_pr,
    stg_github_search__pull_requests.author_username,
    stg_github_search__pull_requests.assignee_username,
    stg_github_search__pull_requests.comment_count,
    stg_github_search__pull_requests.reactions_count,
    stg_github_search__repositories.num_open_issues,
    stg_github_search__repositories.visibility,
    stg_github_search__repositories.is_archived,
    stg_github_search__repositories.created_at_ts AS repo_created_at_ts,
    stg_github_search__repositories.last_updated_ts AS repo_updated_at_ts,
    stg_github_search__repositories.last_push_ts AS repo_last_push_ts
FROM {{ ref('stg_github_search__pull_requests') }}
LEFT JOIN {{ ref('stg_github_search__repositories') }}
    ON
        lower(
            stg_github_search__pull_requests.organization_name
        ) = lower(
            stg_github_search__repositories.repo_namespace
        ) AND lower(
            stg_github_search__pull_requests.repo_name
        ) = lower(stg_github_search__repositories.repo_name)
LEFT JOIN {{ ref('stg_meltanohub__plugins') }}
    ON
        lower(
            stg_meltanohub__plugins.repo
        ) = lower(stg_github_search__repositories.repo_url)
LEFT JOIN
    {{ ref('team_github_ids') }} ON
        stg_github_search__pull_requests.author_id = team_github_ids.user_id
WHERE stg_meltanohub__plugins.repo IS NOT NULL
