{{
    config(materialized='table')
}}

WITH dates AS (

    SELECT DISTINCT event_date FROM {{ ref('fact_cli_events') }}

)

SELECT
    event_date,
    (
        SELECT COUNT(DISTINCT event_exec.project_id)
        FROM
            (
                SELECT
                    fact_cli_events.event_date,
                    fact_cli_events.project_id,
                    SUM(
                        CASE
                            WHEN
                                fact_cli_events.is_exec_event
                                THEN fact_cli_events.event_count
                            ELSE 0
                        END
                    ) AS exec_count
                FROM {{ ref('fact_cli_events') }}
                GROUP BY 1, 2
            ) AS event_exec
        WHERE
            event_exec.event_date BETWEEN DATEADD(
                DAY, -28, dates.event_date
            ) AND dates.event_date
            AND event_exec.exec_count > 1
    ) AS exec_greater_1_monthly,
    (
        SELECT COUNT(DISTINCT pipe_exec.project_id)
        FROM
            (
                SELECT
                    fact_cli_events.event_date,
                    fact_cli_events.project_id,
                    COUNT(DISTINCT
                        CASE
                            WHEN
                                fact_cli_events.is_pipeline_exec_event
                                THEN fact_cli_events.command
                        END
                    ) AS pipeline_count
                FROM {{ ref('fact_cli_events') }}
                GROUP BY 1, 2
            ) AS pipe_exec
        WHERE
            pipe_exec.event_date BETWEEN DATEADD(
                DAY, -28, dates.event_date
            ) AND dates.event_date
            AND pipe_exec.pipeline_count > 1
    ) AS unique_pipe_greater_1_monthly
FROM dates
