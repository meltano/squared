{{ config(materialized='table') }}

WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                CAST(id AS INT)
            ORDER BY DATE_PARSE(_sdc_batched_at, '%Y-%m-%d %H:%i:%s.%f') DESC
        ) AS row_num
    FROM {{ source('tap_github', 'github_repositories') }}

),

renamed AS (

    SELECT
        CAST(id AS INT) AS repo_id,
        node_id AS graphql_node_id,
        org AS organization_name,
        name AS repo_name,
        full_name AS repo_full_name,
        description,
        html_url,
        CAST(json_extract(license, '$.name') as varchar) AS license,
        default_branch,
        TRY(CAST(PARSE_DATETIME(
            updated_at, 'YYYY-MM-dd HH:mm:ssZ'
                ) AS TIMESTAMP)) AS updated_at_ts,
        TRY(CAST(PARSE_DATETIME(
            created_at, 'YYYY-MM-dd HH:mm:ssZ'
                ) AS TIMESTAMP)) AS created_at_ts,
        TRY(CAST(PARSE_DATETIME(
            pushed_at, 'YYYY-MM-dd HH:mm:ssZ'
                ) AS TIMESTAMP)) AS pushed_at_ts,
        homepage AS homepage_url,
        CAST(private AS BOOLEAN) AS is_private,
        CAST(archived AS BOOLEAN) AS is_archived,
        CAST(disabled AS BOOLEAN) AS is_disabled,
        CAST("size" AS INT) AS repo_size_kb,
        CAST(stargazers_count AS INT) AS stargazers_count,
        CAST(fork AS BOOLEAN) AS is_fork,
        topics,
        visibility,
        "language" AS programming_language,
        CAST(forks_count AS INT) AS forks_count,
        CAST(watchers_count AS INT) AS watchers_count,
        CAST(network_count AS INT) AS network_count,
        CAST(subscribers_count AS INT) AS subscribers_count,
        CAST(open_issues_count AS INT) AS open_issues_count
    FROM source
    WHERE row_num = 1

)

SELECT *
FROM renamed