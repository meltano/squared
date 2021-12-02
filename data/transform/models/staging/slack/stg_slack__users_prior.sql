-- The slack_users_prior table comes from running tap-csv target-athena
-- given a local CSV from orbit

WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                id
            ORDER BY DATE_PARSE(_sdc_batched_at, '%Y-%m-%d %H:%i:%s.%f') DESC
        ) AS row_num
    FROM {{ source('tap_slack', 'slack_users_prior') }}

),

renamed AS (

    SELECT
        email,
        SUBSTR(email, STRPOS(email, '@') + 1) AS email_domain,
        NULLIF(company, '') AS company_name
    FROM source
    WHERE row_num = 1

)

SELECT *
FROM renamed
