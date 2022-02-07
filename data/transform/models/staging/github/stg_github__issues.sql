{{ config(materialized='table') }}

WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                id
            ORDER BY DATE_PARSE(_sdc_batched_at, '%Y-%m-%d %H:%i:%s.%f') DESC
        ) AS row_num
    FROM {{ source('tap_github', 'github_issues') }}

),

renamed AS (

    SELECT
        CAST(id AS INT) AS issue_id,
        node_id AS graphql_node_id,
        repo AS repo_name,
        org AS organization_name,
        CAST("number" AS INT) AS issue_number,
        TRY(CAST(PARSE_DATETIME(
            updated_at, 'YYYY-MM-dd HH:mm:ssZ'
                ) AS TIMESTAMP)) AS updated_at_ts,
        TRY(CAST(PARSE_DATETIME(
            created_at, 'YYYY-MM-dd HH:mm:ssZ'
                ) AS TIMESTAMP)) AS created_at_ts,
        TRY(CAST(PARSE_DATETIME(
            closed_at, 'YYYY-MM-dd HH:mm:ssZ'
                ) AS TIMESTAMP)) AS closed_at_ts,
        state,
        title,
        CAST(comments AS INT) AS comment_count,
        author_association,
        body,
        CAST(json_extract("user", '$.id') as INT) AS author_id,
        CAST(json_extract("user", '$.login') as varchar) AS author_username,
        labels,
        reactions,
        CAST(json_extract(assignee, '$.id') as INT) AS assignee_id,
        CAST(json_extract(assignee, '$.login') as varchar) AS assignee_username,
        assignees,
        milestone,
        CAST(locked AS BOOLEAN) AS is_locked
    FROM source
    WHERE row_num = 1
    AND "type" != 'pull_request'

)

SELECT *
FROM renamed