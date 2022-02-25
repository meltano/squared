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
                        _sdc_batched_at, 'YYYY-MM-dd HH:mm:ss.SSSSSS'
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
        author_username,
        CAST(id AS INT) AS issue_id,
        CAST(project_id AS INT) AS project_id,
        CAST(iid AS INT) AS issue_internal_id,
        CAST(milestone_id AS INT) AS milestone_id,
        CAST(epic_id AS INT) AS epic_id,
        CAST(author_id AS INT) AS author_id,
        CAST(assignee_id AS INT) AS assignee_id,
        CAST(closed_by_id AS INT) AS closed_by_id,
        TRY(COALESCE(
            TRY(CAST(
                PARSE_DATETIME(
                    created_at, 'YYYY-MM-dd HH:mm:ss.SSSSSSZ'
                ) AS TIMESTAMP)),
            TRY(CAST(
                PARSE_DATETIME(
                    created_at, 'YYYY-MM-dd HH:mm:ssZ'
                ) AS TIMESTAMP))
            )
        ) AS created_at_ts,
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
