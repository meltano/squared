{{ config(materialized='table') }}

WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                id
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
        archived,
        avatar_url,
        creator_id,
        default_branch,
        description,
        http_url_to_repo,
        id AS project_id,
        merge_method,
        name AS project_name,
        name_with_namespace,
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
        ssh_url_to_repo,
        statistics,
        tag_list,
        visibility_level,
        visibility,
        web_url,
        wiki_enabled,
        CAST(approvals_before_merge AS INT) AS approvals_before_merge,
        CAST(builds_enabled AS BOOLEAN) AS builds_enabled,
        CAST(
            container_registry_enabled AS BOOLEAN
        ) AS container_registry_enabled,
        TRY(CAST(PARSE_DATETIME(
            created_at, 'YYYY-MM-dd HH:mm:ss.SSSSSSZ'
                ) AS TIMESTAMP)) AS created_at,
        CAST(forks_count AS INT) AS forks_count,
        CAST(issues_enabled AS BOOLEAN) AS issues_enabled,
        TRY(CAST(PARSE_DATETIME(
            last_activity_at, 'YYYY-MM-dd HH:mm:ss.SSSSSSZ'
                ) AS TIMESTAMP)) AS last_activity_at,
        CAST(lfs_enabled AS BOOLEAN) AS lfs_enabled,
        CAST(merge_requests_enabled AS BOOLEAN) AS merge_requests_enabled,
        CAST(open_issues_count AS INT) AS open_issues_count,
        CAST(request_access_enabled AS BOOLEAN) AS request_access_enabled,
        CAST(shared_runners_enabled AS BOOLEAN) AS shared_runners_enabled,
        CAST(snippets_enabled AS BOOLEAN) AS snippets_enabled,
        CAST(star_count AS INT) AS star_count
    FROM source
    WHERE row_num = 1

)

SELECT *
FROM renamed
