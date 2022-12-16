SELECT *
FROM {{ ref('stg_github_search__issues_base') }}
WHERE issue_type = 'issue'
