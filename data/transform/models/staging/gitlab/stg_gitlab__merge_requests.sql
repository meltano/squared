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
                        updated_at, 'YYYY-MM-dd HH:mm:ss.SSSSSSZ'
                    ) AS TIMESTAMP
                )) DESC
        ) AS row_num
    FROM {{ source('tap_gitlab', 'gitlab_merge_requests') }}

),

renamed AS (

    SELECT
        project_id,
        id AS merge_request_id,
        iid AS merge_request_internal_id,
        milestone_id,
        author_id,
        assignee_id,
        merged_by_id,
        closed_by_id,
        title,
        description,
        state,
        target_project_id,
        target_branch,
        source_project_id,
        source_branch,
        labels,
        work_in_progress,
        merge_status,
        allow_collaboration,
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
