WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY id
            ORDER BY _sdc_batched_at DESC
        ) AS row_num
    FROM {{ source('tap_github_search', 'pull_requests') }}

),

renamed AS (

    SELECT
        repo AS repo_name,
        org AS organization_name,
        node_id AS graphql_node_id,
        html_url,
        title,
        author_association,
        body,
        merge_commit_sha,
        statuses_url,
        labels,
        assignees,
        requested_reviewers,
        milestone,
        id AS pull_request_id,
        number AS pr_number,
        updated_at AS last_updated_ts,
        created_at AS created_at_ts,
        closed_at AS closed_at_ts,
        merged_at AS merged_at_ts,
        locked AS is_locked,
        draft AS is_draft,
        user:id::INT AS author_id,
        user:login::STRING AS author_username,
        assignee:id::INT AS assignee_id,
        assignee:login::STRING AS assignee_username,
        head:ref::STRING AS head_branch_name,
        base:ref::STRING AS base_branch_name,
        CASE
            WHEN
                state = 'closed'
                AND merged_at IS NOT NULL
                THEN 'merged'
            ELSE state
        END AS state,
        COALESCE(user:type::STRING = 'Bot', FALSE) AS is_bot_user
    FROM source
    WHERE row_num = 1

)

SELECT
    renamed.*,
    stg_github_search__issues_base.reactions,
    COALESCE(stg_github_search__issues_base.comment_count, 0) AS comment_count,
    COALESCE(
        stg_github_search__issues_base.reactions_count, 0
    ) AS reactions_count
FROM renamed
LEFT JOIN {{ ref('stg_github_search__issues_base') }}
    ON renamed.graphql_node_id = stg_github_search__issues_base.graphql_node_id
