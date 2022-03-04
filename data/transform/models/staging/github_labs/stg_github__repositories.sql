{{ config(materialized='table') }}

WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY id
            ORDER BY _sdc_batched_at DESC
        ) AS row_num
    FROM {{ source('tap_github_labs', 'repositories') }}

),

renamed AS (

    SELECT
        node_id AS graphql_node_id,
        org AS organization_name,
        name AS repo_name,
        full_name AS repo_full_name,
        description,
        html_url,
        default_branch,
        homepage AS homepage_url,
        topics,
        visibility,
        language AS programming_language,
        id AS repo_id,
        updated_at AS last_updated_ts,
        created_at AS created_at_ts,
        pushed_at AS pushed_at_ts,
        private AS is_private,
        archived AS is_archived,
        disabled AS is_disabled,
        size AS repo_size_kb,
        stargazers_count,
        fork AS is_fork,
        forks_count,
        watchers_count,
        network_count,
        subscribers_count,
        open_issues_count,
        license:name AS license
    FROM source
    WHERE row_num = 1

)

SELECT *
FROM renamed
