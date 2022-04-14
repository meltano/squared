WITH github AS (
    SELECT DISTINCT
        author_id,
        author_username
    FROM {{ ref('stg_github__issues') }}
    UNION DISTINCT
    SELECT DISTINCT
        author_id,
        author_username

    FROM {{ ref('stg_github__pull_requests') }}
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
    SELECT DISTINCT
        COALESCE(
            name_matches.github_author_id,
            hub.github_id,
            lab.github_id
        ) AS github_author_id,
        COALESCE(
            name_matches.github_author_username,
            hub.github_username,
            lab.github_username
        ) AS github_author_username,
        COALESCE(
            name_matches.gitlab_author_id,
            hub.gitlab_id,
            lab.gitlab_id
        ) AS gitlab_author_id,
        COALESCE(
            name_matches.gitlab_author_username,
            hub.gitlab_username,
            lab.gitlab_username
        ) AS gitlab_author_username
    FROM name_matches
    LEFT JOIN
        {{ ref('contributor_id_mapping') }} AS hub ON
            name_matches.github_author_id = hub.github_id
    LEFT JOIN
        {{ ref('contributor_id_mapping') }} AS lab ON
            name_matches.gitlab_author_id = lab.gitlab_id
)

SELECT
    *,
    {{ dbt_utils.surrogate_key(
        ['github_author_id', 'gitlab_author_id']
    ) }} AS user_surrogate_key
FROM blend_all
