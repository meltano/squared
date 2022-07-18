{{
    config(
        materialized='incremental',
        unique_key='id'
    )
}}

SELECT
    id,
    name as slack_name,
    real_name
FROM users
WHERE is_admin = 'TRUE'

