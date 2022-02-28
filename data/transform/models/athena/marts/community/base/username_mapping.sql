WITH github AS (
    SELECT DISTINCT
        author_id,
        author_username
    FROM dbt_prod.stg_github__issues
    UNION DISTINCT
    SELECT DISTINCT
        author_id,
        author_username

    FROM dbt_prod.stg_github__pull_requests
),

gitlab AS (

    SELECT DISTINCT
        author_id,
        author_username
    FROM {{ ref('stg_gitlab__merge_requests') }}
    UNION DISTINCT
    SELECT DISTINCT
        author_id,
        author_username
    FROM {{ ref('stg_gitlab__issues') }}

),

name_matches AS (
    SELECT
        github.author_id AS github_author_id,
        github.author_username AS github_author_username,
        gitlab.author_id AS gitlab_author_id,
        gitlab.author_username AS gitlab_author_username
    FROM github
    FULL JOIN
        gitlab ON LOWER(github.author_username) = LOWER(gitlab.author_username)
),

blend_all AS (
    SELECT
        COALESCE(
            name_matches.github_author_id,
            contributor_id_mapping.github_id
        ) AS github_author_id,
        COALESCE(
            name_matches.github_author_username,
            contributor_id_mapping.github_username
        ) AS github_author_username,
        COALESCE(
            name_matches.gitlab_author_id,
            contributor_id_mapping.gitlab_id
        ) AS gitlab_author_id,
        COALESCE(
            name_matches.gitlab_author_username,
            contributor_id_mapping.gitlab_username
        ) AS gitlab_author_username
    FROM name_matches
    LEFT JOIN
        {{ ref('contributor_id_mapping') }} ON
            name_matches.github_author_id = contributor_id_mapping.github_id
)

SELECT
    *,
    COALESCE(
        CAST(github_author_id AS VARCHAR), ''
    ) || COALESCE(CAST(gitlab_author_id AS VARCHAR), '') AS user_surrogate_key
FROM blend_all
