{{ config(materialized='view') }}

WITH monthly_elt_message_counts AS (

      SELECT DISTINCT
          monthly_time_index,
          thread_datetime,
          COUNT(CASE WHEN is_tap_message = True THEN 1 END) OVER (PARTITION BY monthly_time_index) AS total_monthly_tap_parent_messages,
          COUNT(CASE WHEN is_target_message = True THEN 1 END) OVER (PARTITION BY monthly_time_index) AS total_monthly_target_parent_messages,
          COUNT(CASE WHEN is_cli_message = True THEN 1 END) OVER (PARTITION BY monthly_time_index) AS total_monthly_cli_parent_messages,
          COUNT(*) OVER (PARTITION BY monthly_time_index) AS total_monthly_parent_messages
      FROM (

          SELECT DISTINCT
              date_trunc('MONTH', thread_datetime) AS monthly_time_index,
              is_tap_message,
              is_target_message,
              is_cli_message,
              thread_datetime,
              message
          FROM categorized_messages
          WHERE thread_datetime = ts_datetime
          ORDER BY monthly_time_index

      ) AS monthly_counts 
      ORDER BY monthly_time_index

), monthly_elt_percentages AS (
  
      SELECT DISTINCT
          monthly_time_index,
          thread_datetime,
          total_monthly_tap_parent_messages/total_monthly_parent_messages *100 AS monthly_tap_parent_message_percentage,
          total_monthly_target_parent_messages/total_monthly_parent_messages *100 AS monthly_target_parent_message_percentage,
          total_monthly_cli_parent_messages/total_monthly_parent_messages *100 AS monthly_cli_parent_message_percentage
      FROM monthly_elt_message_counts
      

), quarterly_elt_message_counts AS (
  
      SELECT DISTINCT
            quarterly_time_index,
            thread_datetime,
            COUNT(CASE WHEN is_tap_message = True THEN 1 END) OVER (PARTITION BY quarterly_time_index) AS total_quarterly_tap_parent_messages,
            COUNT(CASE WHEN is_target_message = True THEN 1 END) OVER (PARTITION BY quarterly_time_index) AS total_quarterly_target_parent_messages,
            COUNT(CASE WHEN is_cli_message = True THEN 1 END) OVER (PARTITION BY quarterly_time_index) AS total_quarterly_cli_parent_messages,
            COUNT(*) OVER (PARTITION BY quarterly_time_index) AS total_quarterly_parent_messages
      FROM (
            SELECT DISTINCT 
                DATE_TRUNC('QUARTER', thread_datetime) AS quarterly_time_index,
                is_tap_message,
                is_target_message,
                is_cli_message,
                thread_datetime,
                message
            FROM categorized_messages
            WHERE thread_datetime = ts_datetime
            ORDER BY quarterly_time_index
      ) AS quarterly_counts 
      ORDER BY quarterly_time_index
  
), quarterly_elt_percentages AS (
  
      SELECT DISTINCT
          quarterly_time_index,
          thread_datetime,
          total_quarterly_tap_parent_messages/total_quarterly_parent_messages *100 AS quarterly_tap_parent_message_percentage,
          total_quarterly_target_parent_messages/total_quarterly_parent_messages *100 AS quarterly_target_parent_message_percentage,
          total_quarterly_cli_parent_messages/total_quarterly_parent_messages *100 AS quarterly_cli_parent_message_percentage
      FROM quarterly_elt_message_counts

), yearly_elt_message_counts AS (

      SELECT DISTINCT
          yearly_time_index,
          thread_datetime,
          COUNT(CASE WHEN is_tap_message = True THEN 1 END) OVER (PARTITION BY yearly_time_index) AS total_yearly_tap_parent_messages,
          COUNT(CASE WHEN is_target_message = True THEN 1 END) OVER (PARTITION BY yearly_time_index) AS total_yearly_target_parent_messages,
          COUNT(CASE WHEN is_cli_message = True THEN 1 END) OVER (PARTITION BY yearly_time_index) AS total_yearly_cli_parent_messages,
          COUNT(*) OVER (PARTITION BY yearly_time_index) AS total_yearly_parent_messages
      FROM (

          SELECT DISTINCT
              date_trunc('YEAR', thread_datetime) AS yearly_time_index,
              is_tap_message,
              is_target_message,
              is_cli_message,
              thread_datetime,
              message
          FROM categorized_messages
          WHERE thread_datetime = ts_datetime
          ORDER BY yearly_time_index

      ) AS yearly_counts 
      ORDER BY yearly_time_index

), yearly_elt_percentages AS (
  
      SELECT
          yearly_time_index,
          thread_datetime,
          total_yearly_tap_parent_messages/total_yearly_parent_messages *100 AS yearly_tap_parent_message_percentage,
          total_yearly_target_parent_messages/total_yearly_parent_messages *100 AS yearly_target_parent_message_percentage,
          total_yearly_cli_parent_messages/total_yearly_parent_messages *100 AS yearly_cli_parent_message_percentage
      FROM yearly_elt_message_counts

), final AS (
      
      SELECT DISTINCT
            monthly_elt_percentages.monthly_time_index AS monthly_time_index,
            monthly_tap_parent_message_percentage,
            monthly_target_parent_message_percentage,
            monthly_cli_parent_message_percentage,
            quarterly_elt_percentages.quarterly_time_index AS quarterly_time_index,
            quarterly_tap_parent_message_percentage,
            quarterly_target_parent_message_percentage,
            quarterly_cli_parent_message_percentage,
            yearly_elt_percentages.yearly_time_index AS yearly_time_index,
            yearly_tap_parent_message_percentage,
            yearly_target_parent_message_percentage,
            yearly_cli_parent_message_percentage
      FROM monthly_elt_percentages
      JOIN quarterly_elt_percentages ON quarterly_elt_percentages.thread_datetime = monthly_elt_percentages.thread_datetime
      JOIN yearly_elt_percentages ON yearly_elt_percentages.thread_datetime = monthly_elt_percentages.thread_datetime

)

SELECT DISTINCT * FROM final
ORDER BY monthly_time_index