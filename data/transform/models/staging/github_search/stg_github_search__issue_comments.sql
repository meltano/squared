{{
    config(
        enabled=false
    )
}}

WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY id
            ORDER BY _sdc_batched_at DESC
        ) AS row_num
    FROM {{ source('tap_github_search', 'issue_comments') }}
),

renamed AS (

    SELECT
        id AS issue_comment_id,
        author_association AS author_association_type,
        created_at AS created_at_ts,
        updated_at AS last_updated_ts,
        org || '/' || repo AS full_name
    FROM source
    WHERE row_num = 1

)

SELECT *
FROM renamed
