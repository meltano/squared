WITH new_member_message AS (

    SELECT
        message_created_at,
        SPLIT_PART(
            SPLIT_PART(message_content, '(<@', 2), '>)', 1
        ) AS parsed_user_id
    FROM {{ ref('stg_slack__messages') }}
    -- new-member-notice channel
    WHERE channel_id = 'C01SK13R9NJ'
        AND slack_username = 'New User Alert [bot]'

)

SELECT
    stg_slack__users.user_id,
    stg_slack__users.email_domain,
    new_member_message.message_created_at
FROM {{ ref('stg_slack__users') }}
LEFT JOIN
    new_member_message ON
        stg_slack__users.user_id = new_member_message.parsed_user_id
WHERE NOT stg_slack__users.is_bot
    AND stg_slack__users.user_id != 'USLACKBOT'
