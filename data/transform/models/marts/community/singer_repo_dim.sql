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
    is_fork,
    is_archived,
    is_disabled,
    size_kb,
    repo_lifespan_days,
    homepage_url,
    connector_type,
    COALESCE(description, 'No Description') AS description
FROM {{ ref('stg_github_search__repositories') }}
WHERE visibility = 'public'

UNION ALL

SELECT
    project_name,
    path_with_namespace,
    project_namespace,
    web_url,
    created_at_ts,
    last_activity_at_ts,
    last_activity_at_ts,
    forks_count,
    open_issues_count,
    star_count,
    0 AS num_watchers,
    batched_at_ts,
    FALSE AS is_fork,
    archived,
    FALSE AS is_disabled,
    NULL AS size_kb,
    repo_lifespan_days,
    NULL AS homepage_url,
    CASE
        WHEN
            project_name LIKE 'tap-%'
            OR project_name LIKE '%-tap-%'
            THEN 'tap'
        ELSE 'target'
    END AS connector_type,
    COALESCE(description, 'No Description') AS description
FROM {{ ref('stg_gitlab__projects') }}
WHERE
    project_namespace = 'hotglue'
    AND (
        LOWER(project_name) LIKE 'tap-%'
        OR
        LOWER(project_name) LIKE 'target-%'
    )
