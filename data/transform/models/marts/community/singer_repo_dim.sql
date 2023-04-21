SELECT
    repo_name,
    repo_full_name,
    repo_namespace,
    repo_url,
    created_at_ts,
    last_push_ts,
    last_updated_ts,
    num_forks,
    num_open_issues,
    num_stargazers,
    num_watchers,
    batch_ts,
    COALESCE(description, 'No Description') as description,
    is_fork,
    is_archived,
    is_disabled,
    size_kb,
    repo_lifespan_days,
    homepage_url,
    connector_type
FROM {{ ref('stg_github_search__repositories') }}
WHERE visibility = 'public'
