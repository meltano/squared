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
                        updated_at, 'YYYY-MM-dd HH:mm:ss.SSSSSSZ'
                    ) AS TIMESTAMP
                )) DESC
        ) AS row_num
    FROM {{ source('tap_gitlab', 'gitlab_merge_requests') }}

),

renamed AS (

    SELECT
        CAST(id AS INT) AS merge_request_id,
        CAST(project_id AS INT) AS project_id,
        CAST(iid AS INT) AS merge_request_internal_id,
        CAST(milestone_id AS INT) AS milestone_id,
        CAST(author_id AS INT) AS author_id,
        CAST(assignee_id AS INT) AS assignee_id,
        CAST(merged_by_id AS INT) AS merged_by_id,
        CAST(closed_by_id AS INT) AS closed_by_id,
        title,
        description,
        state,
        CAST(target_project_id AS INT) AS target_project_id,
        target_branch,
        CAST(source_project_id AS INT) AS source_project_id,
        source_branch,
        labels,
        CAST(work_in_progress AS BOOLEAN) AS is_work_in_progress,
        merge_status,
        CAST(allow_collaboration AS BOOLEAN) AS is_collaboration_allowed,
        TRY(CAST(
            PARSE_DATETIME(
                created_at, 'YYYY-MM-dd HH:mm:ss.SSSSSSZ'
            ) AS TIMESTAMP)) AS created_at_ts,
        TRY(CAST(
            PARSE_DATETIME(
                updated_at, 'YYYY-MM-dd HH:mm:ss.SSSSSSZ'
            ) AS TIMESTAMP)) AS updated_at_ts,
        TRY(CAST(
            PARSE_DATETIME(
                merged_at, 'YYYY-MM-dd HH:mm:ss.SSSSSSZ'
            ) AS TIMESTAMP
        )) AS merged_at_ts,
        TRY(CAST(
            PARSE_DATETIME(
                closed_at, 'YYYY-MM-dd HH:mm:ss.SSSSSSZ'
            ) AS TIMESTAMP
        )) AS closed_at_ts,
        CAST(upvotes AS INT) AS up_votes,
        CAST(downvotes AS INT) AS down_votes,
        CAST(user_notes_count AS INT) AS comment_count
    FROM source
    WHERE row_num = 1

)

SELECT *
FROM renamed
