WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY id
            ORDER BY _sdc_batched_at DESC
        ) AS row_num
    FROM {{ source('tap_github_meltano', 'pull_requests') }}

),

renamed AS (

    SELECT
        repo AS repo_name,
        org AS organization_name,
        node_id AS graphql_node_id,
        html_url,
        state,
        author_association,
        merge_commit_sha,
        statuses_url,
        labels,
        reactions,
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
        comments AS comment_count,
        draft AS is_draft,
        user:id::INT AS author_id,
        user:login::STRING AS author_username,
        assignee:id::INT AS assignee_id,
        assignee:login::STRING AS assignee_username,
        head:ref::STRING AS head_branch_name,
        base:ref::STRING AS base_branch_name
    FROM source
    WHERE row_num = 1

)

SELECT *
FROM renamed
