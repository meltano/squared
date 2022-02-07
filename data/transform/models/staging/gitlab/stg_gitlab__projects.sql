{{ config(materialized='table') }}

WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                CAST(id AS INT)
            ORDER BY
                TRY(CAST(
                    PARSE_DATETIME(
                        last_activity_at, 'YYYY-MM-dd HH:mm:ss.SSSSSSZ'
                    ) AS TIMESTAMP
                )) DESC
        ) AS row_num
    FROM {{ source('tap_gitlab', 'gitlab_projects') }}

),

renamed AS (

    SELECT
        CAST(id AS INT) AS project_id,
        archived,
        avatar_url,
        creator_id,
        default_branch,
        description,
        merge_method,
        name AS project_name,
        REPLACE(name_with_namespace, ' ', '') AS repo_full_name,
        namespace AS project_namespace,
        only_allow_merge_if_all_discussions_are_resolved,
        only_allow_merge_if_build_succeeds,
        owner_id,
        "path" AS path_without_namespace,
        path_with_namespace,
        permissions,
        public,
        public_builds,
        shared_with_groups,
        tag_list,
        visibility,
        web_url,
        wiki_enabled,
        TRY(CAST(PARSE_DATETIME(
            created_at, 'YYYY-MM-dd HH:mm:ss.SSSSSSZ'
                ) AS TIMESTAMP)) AS created_at_ts,
        CAST(forks_count AS INT) AS forks_count,
        CAST(issues_enabled AS BOOLEAN) AS issues_enabled,
        TRY(CAST(PARSE_DATETIME(
            last_activity_at, 'YYYY-MM-dd HH:mm:ss.SSSSSSZ'
                ) AS TIMESTAMP)) AS last_activity_at_ts,
        CAST(open_issues_count AS INT) AS open_issues_count,
        CAST(snippets_enabled AS BOOLEAN) AS snippets_enabled,
        CAST(star_count AS INT) AS star_count
    FROM source
    WHERE row_num = 1

)

SELECT *
FROM renamed
