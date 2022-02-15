WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                id
            ORDER BY DATE_PARSE(_sdc_batched_at, '%Y-%m-%d %H:%i:%s.%f') DESC
        ) AS row_num
    FROM {{ source('tap_slack', 'slack_users') }}

),

renamed AS (

    SELECT
        id AS user_id,
        team_id,
        name AS slack_username,
        real_name,
        tz,
        tz_label,
        who_can_share_contact_card,
        CAST(JSON_EXTRACT(profile, '$.email') AS VARCHAR) AS email,
        CAST(JSON_EXTRACT(profile, '$.title') AS VARCHAR) AS title,
        CAST(deleted AS BOOLEAN) AS is_deleted,
        CAST(is_admin AS BOOLEAN) AS is_admin,
        CAST(is_owner AS BOOLEAN) AS is_owner,
        CAST(is_primary_owner AS BOOLEAN) AS is_primary_owner,
        CAST(is_restricted AS BOOLEAN) AS is_restricted,
        CAST(is_ultra_restricted AS BOOLEAN) AS is_ultra_restricted,
        CAST(is_bot AS BOOLEAN) AS is_bot,
        FROM_UNIXTIME(CAST(updated AS DOUBLE)) AS updated_at,
        CAST(is_app_user AS BOOLEAN) AS is_app_user,
        CAST(is_email_confirmed AS BOOLEAN) AS is_email_confirmed
    FROM source
    WHERE row_num = 1

)

SELECT
    *,
    SUBSTR(email, STRPOS(email, '@') + 1) AS email_domain
FROM renamed
