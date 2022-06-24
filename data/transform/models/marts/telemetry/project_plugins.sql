WITH base_week AS (
    SELECT
        project_id,
        COUNT(DISTINCT plugin_category) AS plugin_cnt,
        DATE_TRUNC('week', event_ts) AS week_date
    FROM {{ ref('fact_plugin_usage') }}
    GROUP BY 2, 3
),

base_month AS (
    SELECT
        project_id,
        COUNT(DISTINCT plugin_category) AS plugin_cnt,
        DATE_TRUNC('month', event_ts) AS month_date
    FROM {{ ref('fact_plugin_usage') }}
    GROUP BY 2, 3
)

SELECT
    COUNT(project_id) AS total_projects,
    SUM(plugin_cnt) AS plugin_score,
    AVG(plugin_cnt) AS avg_plugin_per_proj,
    week_date AS agg_period_date,
    'week' AS agg_period
FROM base_week
GROUP BY 4, 5

UNION ALL

SELECT
    COUNT(project_id) AS total_projects,
    SUM(plugin_cnt) AS plugin_score,
    AVG(plugin_cnt) AS avg_plugin_per_proj,
    month_date AS agg_period_date,
    'month' AS agg_period
FROM base_month
GROUP BY 4, 5
