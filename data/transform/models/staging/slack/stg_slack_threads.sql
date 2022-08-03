WITH source AS (

    SELECT
        {{ dbt_utrils.surrogate_key(
            ['ts', 'client_msg_id', 'user']
        ) }} AS message_surrogate_key,
        *
    FROM {{ source('tap_slack', 'threads') }}

),

clean_source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY 
                message_surrogate_key
            ORDER BY _sdc_batched_at DESC
        ) AS row_number 
    FROM source

),

renamed AS (

    SELECT
        channel_id,
        blocks,
        client_msg_id,
        edited,
        files,
        is_locked AS is_locked,
        latest_reply AS latest_reply_id,
        team,
        text AS message_content,
        type AS message_type,
        upload,
        user AS user_id,
        parent_user_id,
        display_as_bot AS display_as_bot,
        reply_count,
        reply_users AS reply_users,
        reply_users_count AS reply_users_count,
        subscribed AS subscribed,
        TO_TIMESTAMP_NTZ(ts::INT) AS message_created_at,
        TO_TIMESTAMP_NTZ(thread_ts::INT) AS thread_ts
    FROM clean_source
    WHERE row_num = 1

)

SELECT
    *
FROM renamed 