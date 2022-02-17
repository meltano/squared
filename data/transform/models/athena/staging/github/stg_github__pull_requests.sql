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
        repo AS repo_name,
        org AS organization_name,
        node_id AS graphql_node_id,
        html_url,
        state,
        title,
        author_association,
        body,
        merge_commit_sha,
        statuses_url,
        labels,
        reactions,
        assignees,
        requested_reviewers,
        milestone,
        CAST(id AS INT) AS pull_request_id,
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
        CAST(locked AS BOOLEAN) AS is_locked,
        CAST(comments AS INT) AS comment_count,
        CAST(draft AS BOOLEAN) AS is_draft,
        CAST(JSON_EXTRACT("user", '$.id') AS INT) AS author_id,
        CAST(JSON_EXTRACT("user", '$.login') AS VARCHAR) AS author_username,
        CAST(JSON_EXTRACT(assignee, '$.id') AS INT) AS assignee_id,
        CAST(JSON_EXTRACT(assignee, '$.login') AS VARCHAR) AS assignee_username,
        CAST(JSON_EXTRACT(head, '$.ref') AS VARCHAR) AS head_branch_name,
        CAST(JSON_EXTRACT(base, '$.ref') AS VARCHAR) AS base_branch_name
    FROM source
    WHERE row_num = 1

)

SELECT *
FROM renamed
