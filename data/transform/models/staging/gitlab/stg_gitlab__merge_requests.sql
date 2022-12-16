{{ config(materialized='table') }}

WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                id
            ORDER BY _sdc_batched_at DESC
        ) AS row_num
    FROM {{ source('tap_gitlab', 'merge_requests') }}

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
        user_notes_count AS comment_count
    FROM source
    WHERE row_num = 1

)

SELECT *
FROM renamed
