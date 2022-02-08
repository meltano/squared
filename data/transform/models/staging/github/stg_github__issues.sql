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
        node_id AS graphql_node_id,
        repo AS repo_name,
        org AS organization_name,
        state,
        title,
        author_association,
        body,
        labels,
        reactions,
        assignees,
        milestone,
        CAST(id AS INT) AS issue_id,
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
        CAST(comments AS INT) AS comment_count,
        CAST(JSON_EXTRACT("user", '$.id') AS INT) AS author_id,
        CAST(JSON_EXTRACT("user", '$.login') AS VARCHAR) AS author_username,
        CAST(JSON_EXTRACT(assignee, '$.id') AS INT) AS assignee_id,
        CAST(JSON_EXTRACT(assignee, '$.login') AS VARCHAR) AS assignee_username,
        CAST(locked AS BOOLEAN) AS is_locked
    FROM source
    WHERE row_num = 1
        AND "type" != 'pull_request'

)

SELECT *
FROM renamed
