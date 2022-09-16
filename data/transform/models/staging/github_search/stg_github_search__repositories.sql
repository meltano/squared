WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY id
            ORDER BY _sdc_batched_at DESC
        ) AS row_num,
        -- The same repo url shows up as multiple IDs, probably because the
        -- repo was created/deleted/recreated with the same org/repo_name so
        -- the url is the same. We will filter for only the newest created
        -- version.
        ROW_NUMBER() OVER (
            PARTITION BY html_url
            ORDER BY created_at DESC
        ) AS url_row_num
    FROM {{ source('tap_github_search', 'repositories') }}
    WHERE (
        (name LIKE 'tap-%' OR name LIKE '%-tap-%')
        OR (name LIKE 'target-%' OR name LIKE '%-target-%')
    )
    AND name NOT LIKE 'tap-practica-%'
),

renamed AS (

    SELECT
        id AS repo_id,
        name AS repo_name,
        full_name AS repo_full_name,
        fork AS is_fork,
        forks_count AS num_forks,
        open_issues_count AS num_open_issues,
        watchers_count AS num_watchers,
        stargazers_count AS num_stargazers,
        created_at AS created_at_ts,
        pushed_at AS last_push_ts,
        updated_at AS last_updated_ts,
        visibility,
        archived AS is_archived,
        description,
        disabled AS is_disabled,
        homepage AS homepage_url,
        html_url AS repo_url,
        language,
        private AS is_private,
        size AS size_kb,
        _sdc_batched_at AS batch_ts,
        search_name AS repo_search_name,
        SPLIT_PART(full_name, '/', 1) AS repo_namespace,
        DATEDIFF(DAY, created_at, CURRENT_TIMESTAMP()) AS repo_lifespan_days,
        CASE
            WHEN name LIKE 'tap-%'
                 OR name LIKE '%-tap-%'
                THEN 'tap'
            ELSE 'target'
        END AS connector_type
    FROM source
    WHERE row_num = 1 AND url_row_num = 1

)

SELECT *
FROM renamed
