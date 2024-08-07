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
        web_url AS html_url,
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
        web_url AS html_url,
        description,
        title
    FROM source_hotglue
    WHERE row_num = 1

)

SELECT
    renamed.labels,
    renamed.author_username,
    renamed.issue_id,
    renamed.project_id,
    renamed.issue_internal_id,
    renamed.milestone_id,
    renamed.epic_id,
    renamed.author_id,
    renamed.assignee_id,
    renamed.closed_by_id,
    renamed.created_at_ts,
    renamed.updated_at_ts,
    renamed.closed_at_ts,
    renamed.upvotes,
    renamed.downvotes,
    renamed.merge_requests_count,
    renamed.comment_count,
    renamed.description,
    renamed.title,
    renamed.html_url,
    FALSE AS is_bot_user,
    stg_gitlab__projects.project_namespace,
    stg_gitlab__projects.project_name,
    CASE
        WHEN
            renamed.state = 'opened'
            THEN 'open'
        ELSE renamed.state
    END AS state
FROM renamed
LEFT JOIN {{ ref('stg_gitlab__projects') }}
    ON renamed.project_id = stg_gitlab__projects.project_id
