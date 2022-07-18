{{
    config(
        materialized='incremental',
        unique_key='ts_datetime'
    )
}}

SELECT
    channel_id,
    name AS channel_name,
    text AS message,
    TO_TIMESTAMP_NTZ(ts::int) AS ts_datetime, 
    TO_TIMESTAMP_NTZ(thread_ts::int) AS thread_datetime,
    CASE WHEN REGEXP_LIKE(text, '.*[Tt]ap.*') THEN TRUE ELSE FALSE END AS is_tap_message,
    CASE WHEN REGEXP_LIKE(text, '.*[Tt]arget.*') THEN TRUE ELSE FALSE END AS is_target_message,
    CASE WHEN REGEXP_LIKE(text, '.*[Mm]eltano.*') THEN TRUE ELSE FALSE END AS is_cli_message,
    user AS message_sender,
    reply_users
FROM threads
JOIN channels ON channels.id = threads.channel_id
WHERE text NOT LIKE '%has joined the channel%' AND text NOT LIKE '%set the channel%'
ORDER BY thread_datetime, ts_datetime


