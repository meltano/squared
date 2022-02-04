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
    FROM {{ source('tap_gitlab', 'gitlab_issues') }}

),

renamed AS (

    SELECT
        title,
        description,
        state,
        labels,
        project_id,
        id AS issue_id,
        iid AS issue_internal_id,
        milestone_id,
        epic_id,
        author_id,
        assignee_id,
        closed_by_id,
        TRY(CAST(PARSE_DATETIME(
            created_at, 'YYYY-MM-dd HH:mm:ss.SSSSSSZ'
                ) AS TIMESTAMP)) AS created_at_ts,
        TRY(CAST(PARSE_DATETIME(
            updated_at, 'YYYY-MM-dd HH:mm:ss.SSSSSSZ'
                ) AS TIMESTAMP)) AS updated_at_ts,
        TRY(CAST(
            PARSE_DATETIME(
                closed_at, 'YYYY-MM-dd HH:mm:ss.SSSSSSZ'
            ) AS TIMESTAMP
        )) AS closed_at_ts,
        CAST(upvotes AS INT) AS upvotes,
        CAST(downvotes AS INT) AS downvotes,
        CAST(merge_requests_count AS INT) AS merge_requests_count,
        CAST(user_notes_count AS INT) AS comment_count
    FROM source
    WHERE row_num = 1

)

SELECT *
FROM renamed
