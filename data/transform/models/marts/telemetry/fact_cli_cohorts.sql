WITH cohort_snapshots AS (
    SELECT
        DATE_TRUNC('month', fact_cli_projects.first_event_date) AS cohort_id,
        DATE_TRUNC('month', stg_ga__cli_events.event_date) AS snapshot_month,
        COUNT(DISTINCT stg_ga__cli_events.project_id) AS project_id_cnt,
        SUM(stg_ga__cli_events.event_count) AS event_cnt
    FROM {{ ref('stg_ga__cli_events') }}
    LEFT JOIN
        {{ ref('fact_cli_projects') }} ON
            stg_ga__cli_events.project_id = fact_cli_projects.project_id
    GROUP BY 1, 2
),

orig_counts AS (
    SELECT
        cohort_id,
        project_id_cnt AS orig_project_id_cnt,
        event_cnt AS orig_event_cnt
    FROM cohort_snapshots
    WHERE cohort_id = snapshot_month
),

monthly_totals AS (
    SELECT
        DATE_TRUNC('month', stg_ga__cli_events.event_date) AS snapshot_month,
        COUNT(DISTINCT stg_ga__cli_events.project_id) AS project_id_cnt,
        SUM(stg_ga__cli_events.event_count) AS event_cnt
    FROM {{ ref('stg_ga__cli_events') }}
    GROUP BY 1
)

SELECT
    cohort_snapshots.cohort_id,
    cohort_snapshots.snapshot_month,
    cohort_snapshots.project_id_cnt,
    orig_counts.orig_project_id_cnt,
    cohort_snapshots.event_cnt,
    orig_counts.orig_event_cnt
FROM cohort_snapshots
LEFT JOIN
    monthly_totals ON
        cohort_snapshots.snapshot_month = monthly_totals.snapshot_month
LEFT JOIN orig_counts ON cohort_snapshots.cohort_id = orig_counts.cohort_id
