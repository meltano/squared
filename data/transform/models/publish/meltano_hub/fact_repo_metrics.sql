SELECT *
FROM {{ ref('stg_github_search__repositories') }}
WHERE connector_type = 'tap'
