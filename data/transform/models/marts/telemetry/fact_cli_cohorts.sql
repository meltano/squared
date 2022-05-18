WITH cohort_snapshots AS (
    SELECT
        DATE_TRUNC('month', fact_cli_projects.first_event_date) AS cohort_id,
        DATE_TRUNC(
            'month', fact_cli_events.event_date
        ) AS snapshot_month,
        COUNT(DISTINCT fact_cli_events.project_id) AS project_id_cnt,
        COUNT(
            DISTINCT CASE
                WHEN
                    fact_cli_projects.exec_event_total > 1
                    THEN fact_cli_events.project_id
            END
        ) AS project_id_active_cnt,
        SUM(fact_cli_events.event_count) AS event_cnt,
        SUM(
            CASE
                WHEN
                    fact_cli_projects.exec_event_total > 1
                    THEN fact_cli_events.event_count
                ELSE 0
            END
        ) AS active_event_cnt
    FROM {{ ref('fact_cli_events') }}
    LEFT JOIN
        {{ ref('fact_cli_projects') }} ON
            fact_cli_events.project_id = fact_cli_projects.project_id
    GROUP BY 1, 2
),

orig_counts AS (
    SELECT
        cohort_id,
        project_id_cnt AS orig_project_id_cnt,
        project_id_active_cnt AS orig_project_id_active_cnt,
        event_cnt AS orig_event_cnt,
        active_event_cnt AS orig_active_event_cnt
    FROM cohort_snapshots
    WHERE cohort_id = snapshot_month
)

SELECT
    cohort_snapshots.cohort_id,
    cohort_snapshots.snapshot_month AS cohort_month_date,
    cohort_snapshots.project_id_cnt,
    orig_counts.orig_project_id_cnt,
    cohort_snapshots.project_id_active_cnt,
    orig_counts.orig_project_id_active_cnt,
    cohort_snapshots.event_cnt,
    orig_counts.orig_event_cnt,
    cohort_snapshots.active_event_cnt,
    orig_counts.orig_active_event_cnt,
    DATEDIFF(
        MONTH, cohort_snapshots.cohort_id, cohort_snapshots.snapshot_month
    ) AS cohort_month_number
FROM cohort_snapshots
LEFT JOIN orig_counts ON cohort_snapshots.cohort_id = orig_counts.cohort_id
