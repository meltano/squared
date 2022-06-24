WITH base_week AS (
    SELECT
        project_id,
        DATE_TRUNC('week', event_ts) AS week_date,
        COUNT(DISTINCT plugin_category) AS plugin_cnt
    FROM {{ ref('fact_plugin_usage') }}
    GROUP BY 1, 2
),

base_month AS (
    SELECT
        project_id,
        DATE_TRUNC('month', event_ts) AS month_date,
        COUNT(DISTINCT plugin_category) AS plugin_cnt
    FROM {{ ref('fact_plugin_usage') }}
    GROUP BY 1, 2
)

SELECT
    week_date AS agg_period_date,
    'week' AS agg_period,
    COUNT(project_id) AS total_projects,
    SUM(plugin_cnt) AS plugin_score,
    AVG(plugin_cnt) AS avg_plugin_per_proj
FROM base_week
GROUP BY 1, 2

UNION ALL

SELECT
    month_date AS agg_period_date,
    'month' AS agg_period,
    COUNT(project_id) AS total_projects,
    SUM(plugin_cnt) AS plugin_score,
    AVG(plugin_cnt) AS avg_plugin_per_proj
FROM base_month
GROUP BY 1, 2
