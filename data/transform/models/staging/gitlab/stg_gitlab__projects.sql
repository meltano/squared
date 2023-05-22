{{ config(materialized='table') }}

WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                id
            ORDER BY _sdc_batched_at DESC
        ) AS row_num
    FROM {{ source('tap_gitlab', 'projects') }}

    UNION ALL

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                id
            ORDER BY _sdc_batched_at DESC
        ) AS row_num
    FROM {{ source('tap_gitlab_hotglue', 'projects') }}

),

renamed AS (

    SELECT
        archived,
        avatar_url,
        creator_id,
        default_branch,
        description,
        merge_method,
        name AS project_name,
        namespace:full_path::STRING AS project_namespace,
        namespace AS namespace_details,
        only_allow_merge_if_all_discussions_are_resolved,
        only_allow_merge_if_build_succeeds,
        owner_id,
        path AS path_without_namespace,
        path_with_namespace,
        permissions,
        public,
        public_builds,
        shared_with_groups,
        tag_list,
        visibility,
        web_url,
        wiki_enabled,
        id AS project_id,
        created_at AS created_at_ts,
        forks_count,
        issues_enabled AS is_issues_enabled,
        last_activity_at AS last_activity_at_ts,
        open_issues_count,
        snippets_enabled AS is_snippets_enabled,
        star_count,
        _sdc_batched_at AS batched_at_ts,
        REPLACE(name_with_namespace, ' ', '') AS repo_full_name,
        DATEDIFF(DAY, created_at, CURRENT_TIMESTAMP()) AS repo_lifespan_days
    FROM source
    WHERE row_num = 1

)

SELECT *
FROM renamed
