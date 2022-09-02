WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY repo, org
            ORDER BY _sdc_batched_at DESC
        ) AS row_num
    FROM {{ source('tap_github_search', 'readme') }}

),

renamed AS (

    SELECT
        repo AS repo_name,
        org AS repo_namespace,
        CONCAT('https://github.com/', org, repo) AS repo_url,
        size AS size_kb,
        TRY_BASE64_DECODE_STRING(content) AS text
    FROM source
    WHERE row_num = 1

)

SELECT *
FROM renamed
