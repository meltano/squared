WITH plugins AS (
    SELECT *
    FROM {{ ref('active_projects_base') }}
),

plugins_per_project AS (
    SELECT
        date_dim.date_day,
        (
            SELECT COUNT(
                DISTINCT plugins.project_id
            )
            FROM plugins
            WHERE plugins.date_day BETWEEN DATEADD(
                    DAY, -28, date_dim.date_day
                ) AND date_dim.date_day
        ) AS projects_28d,
        (
            SELECT COUNT(
                DISTINCT
                plugins.project_id,
                plugins.plugin_category
            )
            FROM plugins
            WHERE plugins.date_day BETWEEN DATEADD(
                    DAY, -28, date_dim.date_day
                ) AND date_dim.date_day
        ) AS plugin_categories_28d,
        (
            SELECT COUNT(
                DISTINCT plugins.project_id
            )
            FROM plugins
            WHERE plugins.date_day BETWEEN DATEADD(
                    DAY, -14, date_dim.date_day
                ) AND date_dim.date_day
        ) AS projects_14d,
        (
            SELECT COUNT(
                DISTINCT
                plugins.project_id,
                plugins.plugin_category
            )
            FROM plugins
            WHERE plugins.date_day BETWEEN DATEADD(
                    DAY, -14, date_dim.date_day
                ) AND date_dim.date_day
        ) AS plugin_categories_14d,
        (
            SELECT COUNT(
                DISTINCT plugins.project_id
            )
            FROM plugins
            WHERE plugins.date_day BETWEEN DATEADD(
                    DAY, -7, date_dim.date_day
                ) AND date_dim.date_day
        ) AS projects_7d,
        (
            SELECT COUNT(
                DISTINCT
                plugins.project_id,
                plugins.plugin_category
            )
            FROM plugins
            WHERE plugins.date_day BETWEEN DATEADD(
                    DAY, -7, date_dim.date_day
                ) AND date_dim.date_day
        ) AS plugin_categories_7d
    FROM {{ ref('date_dim') }}
    WHERE date_dim.date_day <= CURRENT_TIMESTAMP()
    HAVING projects_28d > 0
)

SELECT
    date_day,
    projects_28d,
    plugin_categories_28d,
    projects_14d,
    plugin_categories_14d,
    projects_7d,
    plugin_categories_7d,
    plugin_categories_28d / NULLIF(projects_28d, 0) AS app_28d,
    plugin_categories_14d / NULLIF(projects_14d, 0) AS app_14d,
    plugin_categories_7d / NULLIF(projects_7d, 0) AS app_7d
FROM plugins_per_project
