WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY id
            ORDER BY _sdc_batched_at DESC
        ) AS row_num
    FROM {{ source('tap_github_search', 'issues') }}

),

renamed AS (

    SELECT
        node_id AS graphql_node_id,
        html_url,
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
        id AS issue_id,
        number AS issue_number,
        updated_at AS last_updated_ts,
        created_at AS created_at_ts,
        closed_at AS closed_at_ts,
        locked AS is_locked,
        type AS issue_type,
        user:id::INT AS author_id,
        user:login::STRING AS author_username,
        assignee:id::INT AS assignee_id,
        assignee:login::STRING AS assignee_username,
        COALESCE(comments, 0) AS comment_count,
        COALESCE(reactions:total_count::INT, 0) AS reactions_count,
        COALESCE(user:type::STRING = 'Bot', FALSE) AS is_bot_user
    FROM source
    WHERE row_num = 1

)

SELECT *
FROM renamed
