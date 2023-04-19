WITH joined AS (
    SELECT
        stg_dynamodb__project_schedules_table.schedule_surrogate_key,
        stg_dynamodb__workload_metadata_table.started_ts::DATE AS date_day,
        stg_dynamodb__workload_metadata_table.cloud_execution_id
    FROM {{ ref('stg_dynamodb__workload_metadata_table') }}
    LEFT JOIN {{ ref('stg_dynamodb__project_schedules_table') }}
        ON
            stg_dynamodb__workload_metadata_table.cloud_schedule_name_hash
            = stg_dynamodb__project_schedules_table.cloud_schedule_name_hash
            AND stg_dynamodb__workload_metadata_table.tenant_resource_key
            = stg_dynamodb__project_schedules_table.tenant_resource_key
            AND stg_dynamodb__workload_metadata_table.cloud_project_id
            = stg_dynamodb__project_schedules_table.cloud_project_id
            AND stg_dynamodb__workload_metadata_table.cloud_environment_name_hash
            = stg_dynamodb__project_schedules_table.cloud_deployment_name_hash
    WHERE
        stg_dynamodb__project_schedules_table.cloud_schedule_name_hash IS NOT NULL

),

schedules AS (
    SELECT DISTINCT schedule_surrogate_key
    FROM joined

),

schedule_runs_daily AS (
    SELECT
        schedule_surrogate_key,
        date_day,
        count(DISTINCT cloud_execution_id) AS daily_runs
    FROM joined
    GROUP BY 1, 2
),

date_schedule_spine AS (
    SELECT
        date_dim.date_day,
        schedules.schedule_surrogate_key
    FROM {{ ref('date_dim') }}
    CROSS JOIN schedules
    WHERE date_day BETWEEN '2023-03-01' AND current_date()
),

base AS (
    SELECT
        date_schedule_spine.date_day,
        date_schedule_spine.schedule_surrogate_key,
        coalesce(schedule_runs_daily.daily_runs, 0) AS daily_runs,
        sum(schedule_runs_daily.daily_runs) OVER (
            PARTITION BY date_schedule_spine.schedule_surrogate_key
            ORDER BY
                date_schedule_spine.date_day ASC
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS rolling_runs_total
    FROM date_schedule_spine
    LEFT JOIN schedule_runs_daily
        ON
            date_schedule_spine.schedule_surrogate_key
            = schedule_runs_daily.schedule_surrogate_key
            AND date_schedule_spine.date_day = schedule_runs_daily.date_day
)

SELECT
    date_day,
    schedule_surrogate_key,
    daily_runs AS schedule_freq_day,
    round(rolling_runs_total / 3) AS schedule_freq_rolling_avg
FROM base
