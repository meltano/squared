select
    issue_id,
    project_id,
    author_id,
    comment_count
FROM {{ ref('stg_gitlab__issues') }}
