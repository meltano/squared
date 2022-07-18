{{ config(materialized='view') }}

WITH parent_messages AS (
    
    SELECT DISTINCT
        date_trunc('YEAR', thread_datetime) AS time_index,
        COUNT(message) OVER (PARTITION BY time_index ORDER BY time_index) AS total_yearly_count_parent_messages
    FROM categorized_messages 
    WHERE thread_datetime = ts_datetime
    ORDER BY time_index

), parent_tap_messages AS (

        SELECT DISTINCT
            date_trunc('YEAR', thread_datetime) AS time_index,
            tap_id,
            COUNT(message) OVER (PARTITION BY tap_id, time_index) AS yearly_message_counts_by_tap,
            COUNT(tap_id) OVER (PARTITION BY time_index ORDER BY time_index) AS total_yearly_count_tap_parent_messages 
        FROM tap_builder 
        WHERE thread_datetime = ts_datetime 
        ORDER BY time_index, tap_id

), parent_target_messages AS (

    SELECT DISTINCT
        date_trunc('YEAR', thread_datetime) AS time_index, 
        target_id,
        COUNT(message) OVER (PARTITION BY target_id, time_index) AS yearly_message_counts_by_target,
        COUNT(target_id) OVER (PARTITION BY time_index ORDER BY time_index) AS total_yearly_count_target_parent_messages 
    FROM target_builder 
    WHERE thread_datetime = ts_datetime 
    ORDER BY time_index, target_id

), parent_cli_messages AS (

    SELECT DISTINCT
        date_trunc('YEAR', thread_datetime) AS time_index, 
        cli_id,
        COUNT(message) OVER (PARTITION BY cli_id, time_index) AS yearly_message_counts_by_cli,
        COUNT(cli_id) OVER (PARTITION BY time_index ORDER BY time_index) AS total_yearly_count_cli_parent_messages 
    FROM cli_builder
    WHERE thread_datetime = ts_datetime 
    ORDER BY time_index, cli_id

), final as (

    SELECT DISTINCT
        parent_messages.time_index,
        tap_id,
        yearly_message_counts_by_tap/total_yearly_count_tap_parent_messages *100 AS tap_percent_of_tap_parent_messages,
        yearly_message_counts_by_tap/total_yearly_count_parent_messages *100 AS tap_percent_of_all_parent_messages,
        target_id,
        yearly_message_counts_by_target/total_yearly_count_target_parent_messages *100 AS target_percent_of_target_parent_messages,
        yearly_message_counts_by_target/total_yearly_count_parent_messages *100 AS target_percent_of_all_parent_messages,
        cli_id,
        yearly_message_counts_by_cli/total_yearly_count_cli_parent_messages *100 AS cli_percent_of_cli_parent_messages,
        yearly_message_counts_by_cli/total_yearly_count_parent_messages *100 AS cli_percent_of_all_parent_messages
    FROM parent_messages
    FULL OUTER JOIN parent_tap_messages ON parent_tap_messages.time_index = parent_messages.time_index
    FULL OUTER JOIN parent_target_messages ON parent_target_messages.time_index = parent_messages.time_index
    FULL OUTER JOIN parent_cli_messages ON parent_cli_messages.time_index = parent_messages.time_index

) 

SELECT * FROM final
ORDER BY time_index