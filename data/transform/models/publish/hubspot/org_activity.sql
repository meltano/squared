WITH base AS (
    SELECT *
    FROM {{ ref('project_dim') }}
    WHERE project_org_name != 'UNKNOWN'
)
,

activity AS (
    SELECT
        base.project_org_name,
        base.project_org_domain,
        COUNT(DISTINCT base.project_id) AS project_ids,
        COALESCE(
            SUM(
                CASE
                    WHEN
                        fact_cli_executions.pipeline_fk IS NOT NULL
                        THEN fact_cli_executions.event_count
                END
            ),
            0
        ) AS pipeline_runs_lm,
        ARRAY_TO_STRING(
            ARRAY_AGG(
                DISTINCT fact_cli_executions.monthly_piplines_active_eom_segment
            ),
            ' || '
        ) AS segments,
        MIN(base.project_first_event_at) AS org_first_event_at,
        MAX(base.project_last_event_at) AS org_last_event_at,
        MIN(base.project_first_active_date) AS org_first_active_date,
        MAX(base.project_last_active_date) AS org_last_active_date,
        MAX(fact_cli_executions.is_currently_active) AS is_currently_active
    FROM {{ ref('fact_cli_executions') }}
    INNER JOIN base
        ON fact_cli_executions.project_id = base.project_id
    WHERE fact_cli_executions.date_day >= DATEADD('month', -1, CURRENT_DATE())
    GROUP BY 1, 2
),

plugins AS (
    SELECT
        base.project_org_name,
        base.project_org_domain,
        COUNT(DISTINCT fact_plugin_usage.plugin_name) AS unique_plugins
    FROM {{ ref('fact_plugin_usage') }}
    INNER JOIN base
        ON fact_plugin_usage.project_id = base.project_id
    WHERE fact_plugin_usage.date_day >= DATEADD('month', -1, CURRENT_DATE())
    GROUP BY 1, 2
)

SELECT
    activity.*,
    plugins.unique_plugins
FROM activity
LEFT JOIN plugins
    ON plugins.project_org_domain = activity.project_org_domain
