WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY id
            ORDER BY _sdc_batched_at DESC
        ) AS row_num
    FROM {{ source('tap_slack', 'users') }}

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
        profile:email::STRING AS email,
        SUBSTR(profile:email::STRING, CHARINDEX('@', profile:email::STRING) + 1) AS email_domain,
        profile:title::STRING AS title,
        deleted AS is_deleted,
        is_admin,
        is_owner,
        is_primary_owner,
        is_restricted,
        is_ultra_restricted,
        is_bot,
        TO_TIMESTAMP_NTZ(updated::INT) AS updated_at,
        is_app_user,
        is_email_confirmed
    FROM source
    WHERE row_num = 1

)

SELECT
    *
FROM renamed
