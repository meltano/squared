{{ config(materialized='view') }}

WITH monthly_date_ranks AS (

    SELECT 
        monthly_time_index,
        ts_datetime,
        thread_datetime,
        rank
    FROM (

        SELECT
            date_trunc('MONTH', thread_datetime) AS monthly_time_index,
            channel_id,
            ts_datetime,
            thread_datetime,
            RANK() OVER (PARTITION BY thread_datetime ORDER BY channel_id, thread_datetime, ts_datetime) AS rank
        FROM categorized_messages
        ORDER BY channel_id, thread_datetime, ts_datetime

    ) AS data
    WHERE rank = 2
    ORDER BY monthly_time_index

), monthly_response_avgs AS (

    SELECT DISTINCT
          monthly_time_index,
          thread_datetime,
          ts_datetime,
          AVG(DATEDIFF(hour, thread_datetime, ts_datetime)) OVER (PARTITION BY monthly_time_index) AS monthly_average_response_time_hrs
    FROM monthly_date_ranks
    ORDER BY monthly_time_index

), quarterly_date_ranks AS (

    SELECT 
        quarterly_time_index,
        ts_datetime,
        thread_datetime,
        rank
    FROM (

        SELECT
            date_trunc('QUARTER', thread_datetime) AS quarterly_time_index,
            channel_id,
            ts_datetime,
            thread_datetime,
            RANK() OVER (PARTITION BY thread_datetime ORDER BY channel_id, thread_datetime, ts_datetime) AS rank
        FROM categorized_messages
        ORDER BY channel_id, thread_datetime, ts_datetime

    ) AS data
    WHERE rank = 2
    ORDER BY quarterly_time_index
  
), quarterly_response_avgs AS (

    SELECT DISTINCT
          quarterly_time_index,
          thread_datetime,
          ts_datetime,
          AVG(DATEDIFF(hour, thread_datetime, ts_datetime)) OVER (PARTITION BY quarterly_time_index) AS quarterly_average_response_time_hrs
    FROM quarterly_date_ranks
    ORDER BY quarterly_time_index

), yearly_date_ranks AS (

    SELECT 
        yearly_time_index,
        ts_datetime,
        thread_datetime,
        rank
    FROM (

        SELECT
            date_trunc('YEAR', thread_datetime) AS yearly_time_index,
            channel_id,
            ts_datetime,
            thread_datetime,
            RANK() OVER (PARTITION BY thread_datetime ORDER BY channel_id, thread_datetime, ts_datetime) AS rank
        FROM categorized_messages
        ORDER BY channel_id, thread_datetime, ts_datetime

    ) AS data
    WHERE rank = 2
    ORDER BY yearly_time_index
  
), yearly_response_avgs AS (

    SELECT DISTINCT
          yearly_time_index,
          thread_datetime,
          ts_datetime,
          AVG(DATEDIFF(hour, thread_datetime, ts_datetime)) OVER (PARTITION BY yearly_time_index) AS yearly_average_response_time_hrs
    FROM yearly_date_ranks
    ORDER BY yearly_time_index
  
), final AS (

    SELECT DISTINCT
        monthly_response_avgs.monthly_time_index AS monthly_time_index,
        monthly_average_response_time_hrs,
        quarterly_response_avgs.quarterly_time_index AS quarterly_time_index,
        quarterly_average_response_time_hrs,
        yearly_response_avgs.yearly_time_index AS yearly_time_index,
        yearly_average_response_time_hrs
    FROM monthly_response_avgs
    FULL OUTER JOIN quarterly_response_avgs ON quarterly_response_avgs.thread_datetime = monthly_response_avgs.thread_datetime
    FULL OUTER JOIN yearly_response_avgs ON yearly_response_avgs.thread_datetime = monthly_response_avgs.thread_datetime
    ORDER BY monthly_time_index
  
)

SELECT * FROM final