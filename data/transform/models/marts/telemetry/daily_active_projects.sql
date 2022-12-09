WITH base AS (
    SELECT
        project_id,
        date_day AS exec_date,
        COUNT(*) AS exec_count
    FROM {{ ref('active_projects_base') }}
    GROUP BY 1, 2
),

daily_project_active AS (
    SELECT DISTINCT
        date_dim.date_day,
        date_dim.last_day_of_month,
        base.project_id
    FROM {{ ref('date_dim') }}
    INNER JOIN base
        ON base.exec_date BETWEEN DATEADD(
            DAY, -28, date_dim.date_day
        ) AND date_dim.date_day
),

project_activity_status AS (
    SELECT
        date_day,
        last_day_of_month,
        project_id,
        COALESCE(
            LAG(
                date_day
            ) OVER (PARTITION BY project_id ORDER BY date_day ASC) IS NULL,
            FALSE
        ) AS is_added_date,
        COALESCE(
            COALESCE(
                LAG(
                    date_day
                ) OVER (
                    PARTITION BY project_id ORDER BY date_day ASC
                ) != DATEADD(DAY, -1, date_day),
                FALSE
            ),
            FALSE
        ) AS is_reactivated_date,
        CASE
            WHEN
                LEAD(
                    date_day
                ) OVER (
                    PARTITION BY project_id ORDER BY date_day ASC
                ) IS NULL THEN TRUE
            WHEN
                LEAD(
                    date_day
                ) OVER (
                    PARTITION BY project_id ORDER BY date_day ASC
                ) != DATEADD(DAY, 1, date_day) THEN TRUE
            ELSE FALSE
        END AS is_last_active_date
    FROM daily_project_active
),

base_daily AS (

    SELECT *
    FROM project_activity_status
    WHERE date_day <= CURRENT_TIMESTAMP()

),

base_monthly AS (
    SELECT
        project_id,
        last_day_of_month,
        DATE_TRUNC(MONTH, last_day_of_month) AS first_day_of_month,
        MIN(date_day) AS min_month_active_dt,
        MAX(date_day) AS max_month_active_dt,
        MAX(CASE WHEN is_added_date THEN date_day END) AS max_added_dt,
        MAX(CASE WHEN is_last_active_date THEN date_day END) AS max_last_day_dt
    FROM base_daily
    GROUP BY 1, 2
)

SELECT
    base_daily.date_day,
    base_daily.last_day_of_month,
    base_daily.project_id,
    base_daily.is_added_date,
    base_daily.is_reactivated_date,
    base_daily.is_last_active_date,
    base_monthly.min_month_active_dt,
    base_monthly.max_month_active_dt,
    COALESCE(
        base_monthly.min_month_active_dt
        = base_monthly.first_day_of_month
        AND COALESCE(
            base_monthly.max_added_dt
            != base_monthly.first_day_of_month,
            TRUE
        ),
        FALSE
    ) AS is_active_month_start,
    COALESCE(
        base_monthly.max_month_active_dt
        = base_monthly.last_day_of_month
        AND COALESCE(
            base_monthly.max_last_day_dt
            != base_monthly.last_day_of_month,
            TRUE
        ),
        FALSE
    ) AS is_active_month_end,
    COALESCE(
        is_active_month_start = TRUE AND is_active_month_end = TRUE, FALSE
    ) AS eom_active_unchanged,
    COALESCE(
        is_active_month_start = FALSE AND is_active_month_end = FALSE, FALSE
    ) AS eom_inactive_unchanged,
    COALESCE(
        is_active_month_start = TRUE AND is_active_month_end = FALSE, FALSE
    ) AS eom_churned,
    COALESCE(
        is_active_month_start = FALSE
        AND is_active_month_end = TRUE
        AND base_monthly.max_added_dt IS NOT NULL,
        FALSE
    ) AS eom_added,
    COALESCE(
        is_active_month_start = FALSE
        AND is_active_month_end = TRUE
        AND base_monthly.max_added_dt IS NULL,
        FALSE
    ) AS eom_reactivated
FROM base_daily
LEFT JOIN base_monthly
    ON base_daily.project_id = base_monthly.project_id
        AND base_daily.last_day_of_month = base_monthly.last_day_of_month
