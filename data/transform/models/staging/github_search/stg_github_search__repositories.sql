WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY id
            ORDER BY _sdc_batched_at DESC
        ) AS row_num
    FROM {{ source('tap_github_search', 'repositories') }}
    WHERE (
        (name like 'tap-%' OR name like '%-tap-%') OR
        (name like 'target-%' OR name like '%-target-%')
    )
      AND name not like 'tap-practica-%'
),

renamed AS (

    SELECT
        id AS repo_id,
        name AS repo_name,
        CASE
            WHEN name LIKE 'tap-%'
              OR name LIKE '%-tap-%'
            THEN 'tap'
            ELSE 'target'
        END AS connector_type,
        full_name AS repo_full_name,
        fork AS is_fork,
        forks AS num_forks,
        open_issues_count AS num_open_issues,
        watchers_count AS num_watchers,
        stargazers_count AS num_stargazers,
        created_at AS created_at_timestamp,
        pushed_at AS last_push_timestamp,
        updated_at AS last_updated_timestamp,
        search_name AS repo_search_name
    FROM source
    WHERE row_num = 1

)

SELECT *
FROM renamed
