WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                ts, COALESCE(client_msg_id, (COALESCE(user, bot_id) || ts))
            ORDER BY _sdc_batched_at DESC
        ) AS row_num
    FROM {{ source('tap_slack', 'messages') }}

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
        text AS message_content,
        reactions,
        reply_users,
        source_team,
        subtype,
        team,
        topic,
        type AS message_type,
        user AS user_id,
        user_team,
        username AS slack_username,
        COALESCE(
            client_msg_id, (COALESCE(user, bot_id) || ts)
        ) AS message_surrogate_key,
        TO_TIMESTAMP_NTZ(ts::INT) AS message_created_at,
        display_as_bot AS display_as_bot,
        is_delayed_message AS is_delayed_message,
        is_intro AS is_intro,
        is_locked AS is_locked,
        is_starred AS is_starred,
        reply_count AS reply_count,
        reply_users_count AS reply_users_count,
        subscribed AS subscribed,
        TO_TIMESTAMP_NTZ(thread_ts::INT) AS thread_ts,
        unread_count AS unread_count,
        upload AS upload
    FROM source
    WHERE row_num = 1

)

SELECT
    *
FROM renamed