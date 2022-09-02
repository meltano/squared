SELECT
	OBJECT_CONSTRUCT(
		'name', sgsr.repo_name,
		'variant', lower(sgsr.REPO_NAMESPACE),
		'namespace', REPLACE(sgsr.repo_name, '-', '_'),
		'label', INITCAP(REPLACE(REPLACE(REPLACE(sgsr.repo_name, 'tap-', ''), 'target-', ''), '-', ' '), ' '),
		'repo', sgsr.REPO_URL,
		'maintenance_status', 'active',
		'keywords', CASE WHEN stg_github_search__readme.TEXT LIKE '%sdk.meltano.com%' THEN ['meltano_sdk'] ELSE [] END,
		'capabilities', CASE WHEN sgsr.connector_type = 'tap' THEN ['catalog', 'discover', 'state'] ELSE [] END,
		'pip_url', CONCAT('git+', sgsr.repo_url, '.git'),
		'settings', [],
		'settings_group_validation', [],
		'domain_url', '',
		'docs', homepage_url,
		'settings_preamble', '',
		'next_steps', '',
		'usage', ''
	) AS plugin_definition,
    sgsr.repo_url,
    sgsr.repo_name AS plugin_name,
    sgsr.REPO_NAMESPACE AS variant,
    NULL AS is_pull_request_open,
    NULL AS is_issue_open
FROM {{ ref('stg_github_search__repositories') }} AS sgsr
LEFT JOIN {{ ref('stg_meltanohub__plugins') }} on sgsr.repo_url = stg_meltanohub__plugins.repo
LEFT JOIN {{ ref('hub_repos_to_exclude') }} on sgsr.repo_url = hub_repos_to_exclude.repo_url
LEFT JOIN {{ ref('stg_github_search__readme') }} on sgsr.repo_url = hub_repos_to_exclude.repo_url
WHERE sgsr.visibility = 'public'
    AND sgsr.is_disabled = FALSE 
    AND sgsr.is_archived = FALSE
    AND sgsr.size_kb > 30
    AND sgsr.repo_lifespan_days > 7
    AND least(sgsr.LAST_UPDATED_TS, sgsr.LAST_PUSH_TS) > dateadd(month, -12, current_date)
    AND stg_meltanohub__plugins.repo IS NULL
    AND sgsr.is_fork = FALSE
    AND hub_repos_to_exclude.repo_url IS NULL