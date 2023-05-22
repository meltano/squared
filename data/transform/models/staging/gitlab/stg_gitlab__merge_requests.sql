{{ config(materialized='table') }}

WITH source_meltano AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                id
            ORDER BY _sdc_batched_at DESC
        ) AS row_num
    FROM {{ source('tap_gitlab', 'merge_requests') }}

),

source_hotglue AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                id
            ORDER BY _sdc_batched_at DESC
        ) AS row_num
    FROM {{ source('tap_gitlab_hotglue', 'merge_requests') }}

),

renamed AS (

    SELECT
        state,
        target_branch,
        source_branch,
        labels,
        merge_status,
        author_username,
        id AS merge_request_id,
        project_id,
        iid AS merge_request_internal_id,
        milestone_id,
        author_id,
        assignee_id,
        merged_by_id,
        closed_by_id,
        target_project_id,
        source_project_id,
        work_in_progress AS is_work_in_progress,
        allow_collaboration AS is_collaboration_allowed,
        created_at AS created_at_ts,
        updated_at AS updated_at_ts,
        merged_at AS merged_at_ts,
        closed_at AS closed_at_ts,
        upvotes,
        downvotes,
        user_notes_count AS comment_count,
        NULL AS description,
        NULL AS title
    FROM source_meltano
    WHERE row_num = 1

    UNION ALL


    SELECT
        state,
        target_branch,
        source_branch,
        labels,
        merge_status,
        author_username,
        id AS merge_request_id,
        project_id,
        iid AS merge_request_internal_id,
        milestone_id,
        author_id,
        assignee_id,
        merged_by_id,
        closed_by_id,
        target_project_id,
        source_project_id,
        work_in_progress AS is_work_in_progress,
        allow_collaboration AS is_collaboration_allowed,
        created_at AS created_at_ts,
        updated_at AS updated_at_ts,
        merged_at AS merged_at_ts,
        closed_at AS closed_at_ts,
        upvotes,
        downvotes,
        user_notes_count AS comment_count,
        description,
        title
    FROM source_hotglue
    WHERE row_num = 1

)

SELECT
    CASE WHEN
        renamed.state = 'opened'
        THEN 'open'
        ELSE renamed.state
    END AS state,
    renamed.target_branch,
    renamed.source_branch,
    renamed.labels,
    renamed.merge_status,
    renamed.author_username,
    renamed.merge_request_id,
    renamed.project_id,
    renamed.merge_request_internal_id,
    renamed.milestone_id,
    renamed.author_id,
    renamed.assignee_id,
    renamed.merged_by_id,
    renamed.closed_by_id,
    renamed.target_project_id,
    renamed.source_project_id,
    renamed.is_work_in_progress,
    renamed.is_collaboration_allowed,
    renamed.created_at_ts,
    renamed.updated_at_ts,
    renamed.merged_at_ts,
    renamed.closed_at_ts,
    renamed.upvotes,
    renamed.downvotes,
    renamed.comment_count,
    renamed.description,
    renamed.title,
    stg_gitlab__projects.project_namespace,
    stg_gitlab__projects.project_name,
    NULL AS html_url,
    FALSE AS is_bot_user
FROM renamed
LEFT JOIN {{ ref('stg_gitlab__projects') }}
    ON renamed.project_id = stg_gitlab__projects.project_id
