{{ config(materialized='table') }}

WITH source_meltano AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                id
            ORDER BY _sdc_batched_at DESC
        ) AS row_num
    FROM {{ source('tap_gitlab', 'issues') }}

),

source_hotglue AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                id
            ORDER BY _sdc_batched_at DESC
        ) AS row_num
    FROM {{ source('tap_gitlab_hotglue', 'issues') }}

),

renamed AS (

    SELECT
        state,
        labels,
        author_username,
        id AS issue_id,
        project_id,
        iid AS issue_internal_id,
        milestone_id,
        epic_id,
        author_id,
        assignee_id,
        closed_by_id,
        created_at AS created_at_ts,
        updated_at AS updated_at_ts,
        closed_at AS closed_at_ts,
        upvotes,
        downvotes,
        merge_requests_count,
        user_notes_count AS comment_count,
        NULL AS description,
        NULL AS title
    FROM source_meltano
    WHERE row_num = 1

    UNION ALL

    SELECT
        state,
        labels,
        author_username,
        id AS issue_id,
        project_id,
        iid AS issue_internal_id,
        milestone_id,
        epic_id,
        author_id,
        assignee_id,
        closed_by_id,
        created_at AS created_at_ts,
        updated_at AS updated_at_ts,
        closed_at AS closed_at_ts,
        upvotes,
        downvotes,
        merge_requests_count,
        user_notes_count AS comment_count,
        description,
        title
    FROM source_hotglue
    WHERE row_num = 1

)

SELECT
    renamed.*,
    stg_gitlab__projects.project_namespace
FROM renamed
LEFT JOIN {{ ref('stg_gitlab__projects') }}
    ON renamed.project_id = stg_gitlab__projects.project_id
