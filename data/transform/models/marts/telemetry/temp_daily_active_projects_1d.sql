WITH base AS (
    SELECT
        project_id,
        date_day AS exec_date,
        COUNT(*) AS exec_count
    FROM {{ ref('temp_active_projects_base_1d') }}
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
)

SELECT *
FROM project_activity_status
WHERE date_day <= CURRENT_TIMESTAMP()
