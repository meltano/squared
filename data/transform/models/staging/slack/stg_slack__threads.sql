WITH source AS (

    SELECT
        {{ dbt_utils.surrogate_key(
            ['ts', 'thread_ts', 'client_msg_id', 'user']
        ) }} AS thread_message_surrogate_key,
        *
    FROM {{ source('tap_slack_public', 'threads') }}

),

clean_source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                thread_message_surrogate_key
            ORDER BY _sdc_batched_at DESC
        ) AS row_num
    FROM source

),

renamed AS (

    SELECT
        thread_message_surrogate_key,
        channel_id,
        blocks,
        client_msg_id,
        edited,
        files,
        is_locked,
        latest_reply AS latest_reply_id,
        team,
        text AS message_content,
        type AS message_type,
        upload,
        user AS user_id,
        parent_user_id,
        display_as_bot,
        reply_count,
        reply_users,
        reply_users_count,
        subscribed,
        TO_TIMESTAMP_NTZ(ts::INT) AS message_created_at,
        TO_TIMESTAMP_NTZ(thread_ts::INT) AS thread_ts
    FROM clean_source
    WHERE row_num = 1

)

SELECT *
FROM renamed
