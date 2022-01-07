{{
    config(materialized='table')
}}

{% set look_back_days = 365 %}

-- ENV is SQLFluff
{% if env_var("SQLFLUFF_TARGET_SCHEMA", "") != "" %}
    {% set look_back_days = 2 %}
{% endif %}

{% for _ in range(1, look_back_days | int) %}

{% if loop.index > 1 %}
UNION ALL
{% endif %}

SELECT
    active_as_of_date,
    COUNT(DISTINCT project_id) AS active_project_id_cnt_28d
FROM (
    SELECT
        event_date,
        project_id,
        (
            CURRENT_DATE - INTERVAL '{{loop.index}}' DAY -- noqa: PRS
        ) AS active_as_of_date
    FROM {{ ref('stg_ga__cli_events') }}
)
WHERE event_date BETWEEN active_as_of_date - INTERVAL '28' DAY -- noqa: PRS
    AND active_as_of_date
GROUP BY 1

{% endfor %}
