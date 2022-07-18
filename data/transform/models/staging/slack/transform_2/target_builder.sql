{{
    config(
        materialized='incremental',
        unique_key='ts_datetime'
    )
}}

{% set target_names = ['airtable', 'athena', 'azureblobstorage', 'bigquery', 'cassandra', 'csv', 'datadotworld', 'gsheet', 'jsonl', 'kinesis', 'magentobi', 'pardot', 'parquet', 'postgres', 'redshift', 'snowflake', 'sqlite', 'stitch', 'uncategorized', 'yaml'] %}

SELECT DISTINCT
    channel_id,
    channel_name,
    message,
    ts_datetime, 
    thread_datetime,
    is_target_message,
    CASE
    {% for target_name in target_names %}
        WHEN REGEXP_LIKE(message, '.*[Tt]arget.*{{target_name}}.*') THEN '{{ target_name }}'
        WHEN REGEXP_LIKE(message, '.*{{target_name}}.*[Tt]arget.*') THEN '{{ target_name }}'
    {% endfor %}
        ELSE 'general_target'
    END AS target_id
FROM categorized_messages
WHERE is_target_message = True
ORDER BY thread_datetime, ts_datetime