WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                ts, COALESCE(client_msg_id, (COALESCE("user", bot_id) || ts))
            ORDER BY DATE_PARSE(_sdc_batched_at, '%Y-%m-%d %H:%i:%s.%f') DESC
        ) AS row_num
    FROM {{ source('tap_slack', 'slack_messages') }}

),

renamed AS (

    SELECT
        channel_id,
        blocks,
        bot_id,
        bot_profile,
        client_msg_id,
        file_id,
        file_ids,
        icons,
        inviter,
        last_read,
        latest_reply AS latest_reply_id,
        name,
        old_name,
        parent_user_id,
        permalink,
        pinned_to,
        purpose,
        "text" AS message_content,
        reactions,
        reply_users,
        source_team,
        subtype,
        team,
        topic,
        "type" AS message_type,
        "user" AS user_id,
        user_team,
        username AS slack_username,
        COALESCE(
            client_msg_id, (COALESCE("user", bot_id) || ts)
        ) AS message_surrogate_key,
        FROM_UNIXTIME(CAST(ts AS DOUBLE)) AS message_created_at,
        CAST(display_as_bot AS BOOLEAN) AS display_as_bot,
        CAST(is_delayed_message AS BOOLEAN) AS is_delayed_message,
        CAST(is_intro AS BOOLEAN) AS is_intro,
        CAST(is_locked AS BOOLEAN) AS is_locked,
        CAST(is_starred AS BOOLEAN) AS is_starred,
        CAST(reply_count AS INT) AS reply_count,
        CAST(reply_users_count AS INT) AS reply_users_count,
        CAST(subscribed AS BOOLEAN) AS subscribed,
        FROM_UNIXTIME(CAST(thread_ts AS DOUBLE)) AS thread_ts,
        CAST(unread_count AS INT) AS unread_count,
        CAST(upload AS BOOLEAN) AS upload
    FROM source
    WHERE row_num = 1

)

SELECT
    *
FROM renamed
