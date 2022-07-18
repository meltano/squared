{{ config(materialized='view') }}

WITH monthly_first_replies AS (

    SELECT
        monthly_time_index,
        thread_datetime,
        first_user_reply,
        id AS employee_id
    FROM (
    
            SELECT
                date_trunc('MONTH', thread_datetime) AS monthly_time_index,
                thread_datetime,
                GET(reply_users, 0) AS first_user_reply
            FROM categorized_messages
            WHERE ts_datetime = thread_datetime
            ORDER BY thread_datetime

    ) AS monthly_repliers
    FULL OUTER JOIN employees ON employees.id = monthly_repliers.first_user_reply
    ORDER BY thread_datetime

), monthly_client_employee_response_avgs AS (
    
    SELECT
        monthly_time_index,
        thread_datetime,
        monthly_client_reply_counts/total_monthly_replies *100 AS monthly_client_response_avg,
        monthly_employee_reply_counts/total_monthly_replies *100 AS monthly_employee_response_avg
    FROM (
      
            SELECT DISTINCT
                monthly_time_index,
                thread_datetime,
                COUNT(CASE WHEN employee_id IS NULL THEN 1 END) OVER (PARTITION BY monthly_time_index) AS monthly_client_reply_counts,
                COUNT(CASE WHEN employee_id IS NOT NULL THEN 1 END) OVER (PARTITION BY monthly_time_index) AS monthly_employee_reply_counts,
                COUNT(*) OVER (PARTITION BY monthly_time_index) AS total_monthly_replies
            FROM monthly_first_replies
            ORDER BY monthly_time_index
    
    ) AS monthly_response_avgs

), quarterly_first_replies AS (

    SELECT
        quarterly_time_index,
        thread_datetime,
        first_user_reply,
        id AS employee_id
    FROM (
      
            SELECT
                date_trunc('QUARTER', thread_datetime) AS quarterly_time_index,
                thread_datetime,
                GET(reply_users, 0) AS first_user_reply
            FROM categorized_messages
            WHERE ts_datetime = thread_datetime
            ORDER BY thread_datetime

    ) AS quarterly_repliers
    FULL OUTER JOIN employees ON employees.id = quarterly_repliers.first_user_reply
    ORDER BY thread_datetime

), quarterly_client_employee_response_avgs AS (
    
    SELECT DISTINCT
        quarterly_time_index,
        thread_datetime,
        quarterly_client_reply_counts/total_quarterly_replies *100 AS quarterly_client_response_avg,
        quarterly_employee_reply_counts/total_quarterly_replies *100 AS quarterly_employee_response_avg
    FROM (
      
            SELECT DISTINCT
                quarterly_time_index,
                thread_datetime,
                COUNT(CASE WHEN employee_id IS NULL THEN 1 END) OVER (PARTITION BY quarterly_time_index) AS quarterly_client_reply_counts,
                COUNT(CASE WHEN employee_id IS NOT NULL THEN 1 END) OVER (PARTITION BY quarterly_time_index) AS quarterly_employee_reply_counts,
                COUNT(*) OVER (PARTITION BY quarterly_time_index) AS total_quarterly_replies
            FROM quarterly_first_replies
            ORDER BY quarterly_time_index
    
    ) AS quarterly_response_avgs

), yearly_first_replies AS (

    SELECT
        yearly_time_index,
        thread_datetime,
        first_user_reply,
        id AS employee_id
    FROM (
      
            SELECT
                date_trunc('YEAR', thread_datetime) AS yearly_time_index,
                thread_datetime,
                GET(reply_users, 0) AS first_user_reply
            FROM categorized_messages
            WHERE ts_datetime = thread_datetime
            ORDER BY thread_datetime

    ) AS yearly_repliers
    FULL OUTER JOIN employees ON employees.id = yearly_repliers.first_user_reply
    ORDER BY thread_datetime

), yearly_client_employee_response_avgs AS (
    
    SELECT DISTINCT
        yearly_time_index,
        thread_datetime,
        yearly_client_reply_counts/total_yearly_replies *100 AS yearly_client_response_avg,
        yearly_employee_reply_counts/total_yearly_replies *100 AS yearly_employee_response_avg
    FROM (
      
            SELECT DISTINCT
                yearly_time_index,
                thread_datetime,
                COUNT(CASE WHEN employee_id IS NULL THEN 1 END) OVER (PARTITION BY yearly_time_index) AS yearly_client_reply_counts,
                COUNT(CASE WHEN employee_id IS NOT NULL THEN 1 END) OVER (PARTITION BY yearly_time_index) AS yearly_employee_reply_counts,
                COUNT(*) OVER (PARTITION BY yearly_time_index) AS total_yearly_replies
            FROM yearly_first_replies
            ORDER BY yearly_time_index
    
    ) AS yearly_response_avgs

), final AS (

    SELECT
        monthly_time_index,
        monthly_client_response_avg,
        monthly_employee_response_avg,
        quarterly_time_index,
        quarterly_client_response_avg,
        quarterly_employee_response_avg,
        yearly_time_index,
        yearly_client_response_avg,
        yearly_employee_response_avg
    FROM monthly_client_employee_response_avgs
    JOIN quarterly_client_employee_response_avgs ON quarterly_client_employee_response_avgs.thread_datetime =
        monthly_client_employee_response_avgs.thread_datetime
    JOIN yearly_client_employee_response_avgs ON yearly_client_employee_response_avgs.thread_datetime = 
        monthly_client_employee_response_avgs.thread_datetime
    ORDER BY monthly_time_index

)

SELECT * FROM final