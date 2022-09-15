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
        size AS size_kb,
        CONCAT('https://github.com/', org, '/', repo) AS repo_url,
        TRY_BASE64_DECODE_STRING(REPLACE(content, '\\n', '')) AS readme_text
    FROM source
    WHERE row_num = 1

)

SELECT *
FROM renamed
