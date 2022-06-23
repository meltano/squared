{{
    config(
        materialized='incremental',
        unique_key='ts_datetime'
    )
}}

{% set cli_commands = ['add', 'config', 'discover', 'elt', 'environment', 'init', 'install', 'invoke', 'remove', 'run', 'schedule', 'select', 'test', 'ui', 'uncategorized', 'user', 'upgrade', 'version'] %}

SELECT DISTINCT
    channel_id,
    channel_name,
    message,
    ts_datetime, 
    thread_datetime,
    is_cli_message,
    CASE
    {% for cli_command in cli_commands %}
        WHEN REGEXP_LIKE(message, '.*[Mm]eltano.*{{cli_command}}.*') THEN '{{ cli_command }}'
    {% endfor %}
        ELSE 'general_cli'
    END AS cli_id
FROM categorized_messages
WHERE is_cli_message = True
ORDER BY thread_datetime, ts_datetime