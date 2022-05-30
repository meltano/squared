WITH base AS (
    SELECT
        structured_events.project_id,
        structured_events.event_id,
        structured_events.event_count,
        structured_events.event_created_at,
        projects.first_event_at,
        projects.activation_date,
        projects.last_activate_at,
        COALESCE(structured_events.event_created_at >= projects.activation_date
            AND structured_events.event_created_at <= projects.last_activate_at,
            FALSE) AS is_active
    FROM {{ ref('structured_events') }}
    LEFT JOIN
        {{ ref('projects') }} ON
            structured_events.project_id = projects.project_id
),

plugin_categories_agg AS (

    SELECT
        'week' AS period_grain,
        'active' AS agg_type,
        DATE_TRUNC(
            'week', base.event_created_at
        ) AS period_date,
        base.project_id,
        COUNT(DISTINCT fact_plugin_usage.plugin_category) AS plugin_distinct_cnt
    FROM base
    INNER JOIN {{ ref('fact_plugin_usage') }}
        ON base.event_id = fact_plugin_usage.event_id
    -- Active
    WHERE base.is_active
    GROUP BY 1, 2, 3, 4

    UNION ALL

    SELECT
        'week' AS period_grain,
        'active_prod' AS agg_type,
        DATE_TRUNC(
            'week', base.event_created_at
        ) AS period_date,
        base.project_id,
        COUNT(
            DISTINCT CASE
                WHEN
                    environments.env_name = 'prod'
                    THEN fact_plugin_usage.plugin_category
            END
        ) AS plugin_distinct_cnt
    FROM base
    INNER JOIN {{ ref('fact_plugin_usage') }}
        ON base.event_id = fact_plugin_usage.event_id
    LEFT JOIN
        {{ ref('environments') }} ON
            base.event_id = environments.event_id
    -- Active
    WHERE base.is_active
    GROUP BY 1, 2, 3, 4

    UNION ALL

    SELECT
        'week' AS period_grain,
        'active_dev' AS agg_type,
        DATE_TRUNC(
            'week', base.event_created_at
        ) AS period_date,
        base.project_id,
        COUNT(
            DISTINCT CASE
                WHEN
                    environments.env_name = 'dev'
                    THEN fact_plugin_usage.plugin_category
            END
        ) AS plugin_distinct_cnt
    FROM base
    INNER JOIN {{ ref('fact_plugin_usage') }}
        ON base.event_id = fact_plugin_usage.event_id
    LEFT JOIN
        {{ ref('environments') }} ON
            base.event_id = environments.event_id
    WHERE base.is_active
    GROUP BY 1, 2, 3, 4

),

cohort_snapshots AS (

    -- Event usage for all projects at the month grain
    SELECT
        'month' AS period_grain,
        DATE_TRUNC(
            'month', event_created_at
        ) AS snapshot_period,
        DATE_TRUNC('month', first_event_at) AS cohort_id,
        DATEDIFF(
            MONTH,
            DATE_TRUNC('month', first_event_at),
            DATE_TRUNC('month', event_created_at)
        ) AS cohort_number,
        'event_volume' AS cohort_type,
        SUM(event_count) AS snapshot_value
    FROM base
    GROUP BY 1, 2, 3, 4, 5

    UNION ALL

    -- Active projects at the month grain
    SELECT
        'month' AS period_grain,
        DATE_TRUNC(
            'month', event_created_at
        ) AS snapshot_period,
        DATE_TRUNC('month', first_event_at) AS cohort_id,
        DATEDIFF(
            MONTH,
            DATE_TRUNC('month', first_event_at),
            DATE_TRUNC('month', event_created_at)
        ) AS cohort_number,
        'active_projects' AS cohort_type,
        COUNT(DISTINCT project_id) AS snapshot_value
    FROM base
    WHERE is_active
    GROUP BY 1, 2, 3, 4, 5

    UNION ALL

    -- APP for active projects at the week grain
    SELECT
        'week' AS period_grain,
        DATE_TRUNC(
            'week', base.event_created_at
        ) AS snapshot_period,
        DATE_TRUNC('week', base.first_event_at) AS cohort_id,
        DATEDIFF(
            WEEK,
            DATE_TRUNC('week', base.first_event_at),
            DATE_TRUNC('week', base.event_created_at)
        ) AS cohort_number,
        'APP_active' AS cohort_type,
        AVG(plugin_categories_agg.plugin_distinct_cnt) AS snapshot_value
    FROM base
    LEFT JOIN
        plugin_categories_agg ON
            base.project_id = plugin_categories_agg.project_id
            AND DATE_TRUNC(
                'week', base.event_created_at
            ) = plugin_categories_agg.period_date
    WHERE base.is_active
        AND plugin_categories_agg.period_grain = 'week'
        AND plugin_categories_agg.agg_type = 'active'
    GROUP BY 1, 2, 3, 4, 5

    UNION ALL

    -- APP for active projects at the month grain
    SELECT
        'month' AS period_grain,
        DATE_TRUNC(
            'month', base.event_created_at
        ) AS snapshot_period,
        DATE_TRUNC('month', base.first_event_at) AS cohort_id,
        DATEDIFF(
            MONTH,
            DATE_TRUNC('month', base.first_event_at),
            DATE_TRUNC('month', base.event_created_at)
        ) AS cohort_number,
        'APP_active' AS cohort_type,
        AVG(plugin_categories_agg.plugin_distinct_cnt) AS snapshot_value
    FROM base
    LEFT JOIN
        plugin_categories_agg ON
            base.project_id = plugin_categories_agg.project_id
            AND DATE_TRUNC(
                'month', base.event_created_at
            ) = plugin_categories_agg.period_date
    WHERE base.is_active
        AND plugin_categories_agg.period_grain = 'month'
        AND plugin_categories_agg.agg_type = 'active'
    GROUP BY 1, 2, 3, 4, 5

    UNION ALL

    -- APP for active projects using the prod environment at the week grain
    SELECT
        'week' AS period_grain,
        DATE_TRUNC(
            'week', base.event_created_at
        ) AS snapshot_period,
        DATE_TRUNC('week', base.first_event_at) AS cohort_id,
        DATEDIFF(
            WEEK,
            DATE_TRUNC('week', base.first_event_at),
            DATE_TRUNC('week', base.event_created_at)
        ) AS cohort_number,
        'APP_active_prod' AS cohort_type,
        AVG(plugin_categories_agg.plugin_distinct_cnt) AS snapshot_value
    FROM base
    LEFT JOIN
        plugin_categories_agg ON
            base.project_id = plugin_categories_agg.project_id
            AND DATE_TRUNC(
                'week', base.event_created_at
            ) = plugin_categories_agg.period_date
    WHERE base.is_active
        AND plugin_categories_agg.period_grain = 'week'
        AND plugin_categories_agg.agg_type = 'active_prod'
    GROUP BY 1, 2, 3, 4, 5

    UNION ALL

    -- APP for active projects using the dev environment at the week grain
    SELECT
        'week' AS period_grain,
        DATE_TRUNC(
            'week', base.event_created_at
        ) AS snapshot_period,
        DATE_TRUNC('week', base.first_event_at) AS cohort_id,
        DATEDIFF(
            WEEK,
            DATE_TRUNC('week', base.first_event_at),
            DATE_TRUNC('week', base.event_created_at)
        ) AS cohort_number,
        'APP_active_dev' AS cohort_type,
        AVG(plugin_categories_agg.plugin_distinct_cnt) AS snapshot_value
    FROM base
    LEFT JOIN
        plugin_categories_agg ON
            base.project_id = plugin_categories_agg.project_id
            AND DATE_TRUNC(
                'week', base.event_created_at
            ) = plugin_categories_agg.period_date
    WHERE base.is_active
        AND plugin_categories_agg.period_grain = 'week'
        AND plugin_categories_agg.agg_type = 'active_dev'
    GROUP BY 1, 2, 3, 4, 5

),

originals AS (
    SELECT
        cohort_id,
        snapshot_value,
        cohort_type
    FROM cohort_snapshots
    WHERE cohort_id = snapshot_period
)

SELECT
    cohort_snapshots.period_grain,
    cohort_snapshots.cohort_id,
    cohort_snapshots.snapshot_period,
    cohort_snapshots.cohort_type,
    cohort_snapshots.snapshot_value,
    cohort_snapshots.cohort_number,
    originals.snapshot_value AS original_snapshot_value
FROM cohort_snapshots
LEFT JOIN originals ON cohort_snapshots.cohort_id = originals.cohort_id
