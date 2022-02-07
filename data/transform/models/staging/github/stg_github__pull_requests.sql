{{ config(materialized='table') }}

WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                CAST(id AS INT)
            ORDER BY DATE_PARSE(_sdc_batched_at, '%Y-%m-%d %H:%i:%s.%f') DESC
        ) AS row_num
    FROM {{ source('tap_github', 'github_pull_requests') }}

),

renamed AS (

    SELECT
        CAST(id AS INT) AS pull_request_id,
        repo AS repo_name,
        org AS organization_name,
        node_id AS graphql_node_id,
        html_url,
        CAST("number" AS INT) AS pr_number,
        TRY(CAST(PARSE_DATETIME(
            updated_at, 'YYYY-MM-dd HH:mm:ssZ'
                ) AS TIMESTAMP)) AS updated_at_ts,
        TRY(CAST(PARSE_DATETIME(
            created_at, 'YYYY-MM-dd HH:mm:ssZ'
                ) AS TIMESTAMP)) AS created_at_ts,
        TRY(CAST(PARSE_DATETIME(
            closed_at, 'YYYY-MM-dd HH:mm:ssZ'
                ) AS TIMESTAMP)) AS closed_at_ts,
        TRY(CAST(PARSE_DATETIME(
            merged_at, 'YYYY-MM-dd HH:mm:ssZ'
                ) AS TIMESTAMP)) AS merged_at_ts,
        state,
        title,
        CAST(locked AS BOOLEAN) AS is_locked,
        CAST(comments AS INT) AS comment_count,
        author_association,
        body,
        merge_commit_sha,
        CAST(draft AS BOOLEAN) AS is_draft,
        statuses_url,
        CAST(json_extract("user", '$.id') as INT) AS author_id,
        CAST(json_extract("user", '$.login') as VARCHAR) AS author_username,
        labels,
        reactions,
        CAST(json_extract(assignee, '$.id') as INT) AS assignee_id,
        CAST(json_extract(assignee, '$.login') as VARCHAR) AS assignee_username,
        assignees,
        requested_reviewers,
        milestone,
        CAST(json_extract(head, '$.ref') as VARCHAR) AS head_branch_name,
        CAST(json_extract(base, '$.ref') as VARCHAR) AS base_branch_name
    FROM source
    WHERE row_num = 1

)

SELECT *
FROM renamed