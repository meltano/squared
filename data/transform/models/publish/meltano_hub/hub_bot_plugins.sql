SELECT
    singer_repo_dim.repo_url,
    singer_repo_dim.repo_name AS plugin_name,
    singer_repo_dim.repo_namespace AS plugin_variant,
    NULL AS is_pull_request_open,
    NULL AS is_issue_open,
    OBJECT_CONSTRUCT(
        'name', singer_repo_dim.repo_name,
        'variant', LOWER(singer_repo_dim.repo_namespace),
        'namespace',
        REPLACE(singer_repo_dim.repo_name, '-', '_'),
        'label',
        INITCAP(
            REPLACE(
                REPLACE(
                    REPLACE(
                        singer_repo_dim.repo_name, 'tap-', ''
                    ),
                    'target-',
                    ''
                ),
                '-',
                ' '
            ),
            ' '
        ),
        'repo', singer_repo_dim.repo_url,
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
                singer_repo_dim.connector_type = 'tap' THEN
                [
                    'catalog', 'discover', 'state'
                ]
            ELSE []
        END,
        'pip_url',
        CONCAT('git+', singer_repo_dim.repo_url, '.git'),
        'settings', [],
        'settings_group_validation', [],
        'domain_url', '',
        'docs', singer_repo_dim.homepage_url,
        'settings_preamble', '',
        'next_steps', '',
        'usage', ''
    ) AS plugin_definition
FROM {{ ref('singer_repo_dim') }}
LEFT JOIN
    {{ ref('stg_meltanohub__plugins') }} ON
    singer_repo_dim.repo_url = stg_meltanohub__plugins.repo
LEFT JOIN
    {{ ref('hub_repos_to_exclude') }} ON
    singer_repo_dim.repo_url = hub_repos_to_exclude.repo_url
LEFT JOIN
    {{ ref('stg_github_search__readme') }} ON
    singer_repo_dim.repo_url
    = stg_github_search__readme.repo_url
WHERE
    singer_repo_dim.visibility = 'public'
    AND singer_repo_dim.is_disabled = FALSE
    AND singer_repo_dim.is_archived = FALSE
    AND singer_repo_dim.size_kb > 30
    AND singer_repo_dim.repo_lifespan_days > 7
    AND LEAST(
        singer_repo_dim.last_updated_ts,
        singer_repo_dim.last_push_ts
    ) > DATEADD(MONTH, -12, CURRENT_DATE)
    AND stg_meltanohub__plugins.repo IS NULL
    AND singer_repo_dim.is_fork = FALSE
    AND hub_repos_to_exclude.repo_url IS NULL
