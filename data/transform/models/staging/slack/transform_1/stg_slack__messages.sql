WITH source AS (

    SELECT
        {{ dbt_utils.surrogate_key(
            ['ts', 'client_msg_id', 'user', 'bot_id']
        ) }} AS message_surrogate_key,
        *
    FROM {{ source('tap_slack', 'messages') }}

),

clean_source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                message_surrogate_key
            ORDER BY _sdc_batched_at DESC
        ) AS row_num
    FROM source

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
        display_as_bot AS display_as_bot,
        is_delayed_message AS is_delayed_message,
        is_intro AS is_intro,
        is_locked AS is_locked,
        is_starred AS is_starred,
        reply_count AS reply_count,
        reply_users_count AS reply_users_count,
        subscribed AS subscribed,
        unread_count AS unread_count,
        upload AS upload,
        message_surrogate_key,
        TO_TIMESTAMP_NTZ(ts::INT) AS message_created_at,
        TO_TIMESTAMP_NTZ(thread_ts::INT) AS thread_ts
    FROM clean_source
    WHERE row_num = 1

)

SELECT
    *
FROM renamed
