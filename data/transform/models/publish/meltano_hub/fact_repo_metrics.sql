WITH repos AS (
    -- Dedupe repos with different ids but same full_repo_name.
    -- Maybe from migrating a repo.
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY repo_full_name
            ORDER BY created_at_ts DESC
        ) AS row_num
    FROM {{ ref('stg_github_search__repositories') }}
    WHERE connector_type = 'tap'
)

SELECT *
FROM repos
WHERE row_num = 1
