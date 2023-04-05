{{
    config(materialized='table')
}}

SELECT
    date_day AS event_date,
    (
        SELECT COUNT(DISTINCT event_exec.project_id)
        FROM
            (
                SELECT
                    fact_cli_executions.date_day,
                    fact_cli_executions.project_id,
                    SUM(
                        CASE
                            WHEN
                                fact_cli_executions.cli_command IN (
                                    'invoke',
                                    'elt',
                                    'run',
                                    'test',
                                    'ui'
                                )
                                THEN fact_cli_executions.event_count
                            ELSE 0
                        END
                    ) AS exec_count
                FROM {{ ref('fact_cli_executions') }}
                GROUP BY 1, 2
            ) AS event_exec
        WHERE
            event_exec.date_day BETWEEN DATEADD(
                DAY, -28, date_dim.date_day
            ) AND date_dim.date_day
            AND event_exec.exec_count > 1
    ) AS exec_greater_1_monthly,
    (
        SELECT COUNT(DISTINCT pipe_exec.project_id)
        FROM
            (
                SELECT
                    fact_cli_executions.date_day,
                    fact_cli_executions.project_id,
                    COUNT(
                        DISTINCT
                        fact_cli_executions.pipeline_fk
                    ) AS pipeline_count
                FROM {{ ref('fact_cli_executions') }}
                GROUP BY 1, 2
            ) AS pipe_exec
        WHERE
            pipe_exec.date_day BETWEEN DATEADD(
                DAY, -28, date_dim.date_day
            ) AND date_dim.date_day
            AND pipe_exec.pipeline_count > 1
    ) AS unique_pipe_greater_1_monthly
FROM {{ ref('date_dim') }}
WHERE
    date_day
    BETWEEN DATEADD(YEAR, -2, CURRENT_TIMESTAMP())
    AND CURRENT_TIMESTAMP()
