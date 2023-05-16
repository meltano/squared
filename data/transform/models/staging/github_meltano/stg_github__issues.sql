WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY id
            ORDER BY _sdc_batched_at DESC
        ) AS row_num
    FROM {{ source('tap_github_meltano', 'issues') }}

),

renamed AS (

    SELECT
        node_id AS graphql_node_id,
        repo AS repo_name,
        org AS organization_name,
        state,
        author_association,
        labels,
        reactions,
        assignees,
        milestone,
        id AS issue_id,
        number AS issue_number,
        updated_at AS last_updated_ts,
        created_at AS created_at_ts,
        closed_at AS closed_at_ts,
        comments AS comment_count,
        locked AS is_locked,
        user:id::INT AS author_id,
        user:login::STRING AS author_username,
        assignee:id::INT AS assignee_id,
        assignee:login::STRING AS assignee_username,
        COALESCE(user:type::STRING = 'Bot', FALSE) AS is_bot_user
    FROM source
    WHERE
        row_num = 1
        AND type != 'pull_request'

)

SELECT *
FROM renamed
