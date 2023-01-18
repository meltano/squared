WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                id
            ORDER BY _sdc_batched_at DESC
        ) AS row_num
    FROM {{ source('tap_gitlab', 'issues') }}

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
        user_notes_count AS comment_count
    FROM source
    WHERE row_num = 1

)

SELECT *
FROM renamed
