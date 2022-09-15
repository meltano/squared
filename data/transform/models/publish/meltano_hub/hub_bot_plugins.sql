SELECT
    stg_github_search__repositories.repo_url,
    stg_github_search__repositories.repo_name AS plugin_name,
    stg_github_search__repositories.repo_namespace AS plugin_variant,
    NULL AS is_pull_request_open,
    NULL AS is_issue_open,
    OBJECT_CONSTRUCT(
        'name', stg_github_search__repositories.repo_name,
        'variant', LOWER(stg_github_search__repositories.repo_namespace),
        'namespace',
        REPLACE(stg_github_search__repositories.repo_name, '-', '_'),
        'label',
        INITCAP(
            REPLACE(
                REPLACE(
                    REPLACE(
                        stg_github_search__repositories.repo_name, 'tap-', ''
                    ),
                    'target-',
                    ''
                ),
                '-',
                ' '
            ),
            ' '
        ),
        'repo', stg_github_search__repositories.repo_url,
        'maintenance_status', 'active',
        'keywords',
        CASE
            WHEN
                stg_github_search__readme.readme_text LIKE '%sdk.meltano.com%'
                THEN ['meltano_sdk']
            ELSE []
        END,
        'capabilities',
        CASE
            WHEN
                stg_github_search__repositories.connector_type = 'tap' THEN [
                    'catalog', 'discover', 'state'
                ]
            ELSE []
        END,
        'pip_url',
        CONCAT('git+', stg_github_search__repositories.repo_url, '.git'),
        'settings', [],
        'settings_group_validation', [],
        'domain_url', '',
        'docs', stg_github_search__repositories.homepage_url,
        'settings_preamble', '',
        'next_steps', '',
        'usage', ''
    ) AS plugin_definition
FROM {{ ref('stg_github_search__repositories') }}
LEFT JOIN
    {{ ref('stg_meltanohub__plugins') }} ON
        stg_github_search__repositories.repo_url = stg_meltanohub__plugins.repo
LEFT JOIN
    {{ ref('hub_repos_to_exclude') }} ON
        stg_github_search__repositories.repo_url = hub_repos_to_exclude.repo_url
LEFT JOIN
    {{ ref('stg_github_search__readme') }} ON
        stg_github_search__repositories.repo_url
        = stg_github_search__readme.repo_url
WHERE stg_github_search__repositories.visibility = 'public'
    AND stg_github_search__repositories.is_disabled = FALSE
    AND stg_github_search__repositories.is_archived = FALSE
    AND stg_github_search__repositories.size_kb > 30
    AND stg_github_search__repositories.repo_lifespan_days > 7
    AND LEAST(
        stg_github_search__repositories.last_updated_ts,
        stg_github_search__repositories.last_push_ts
    ) > DATEADD(MONTH, -12, CURRENT_DATE)
    AND stg_meltanohub__plugins.repo IS NULL
    AND stg_github_search__repositories.is_fork = FALSE
    AND hub_repos_to_exclude.repo_url IS NULL
