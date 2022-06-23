{{
    config(
        materialized='incremental',
        unique_key='id'
    )
}}

SELECT
    id,
    name as slack_name,
    real_name,
    is_admin
FROM users
WHERE is_admin = 'FALSE'