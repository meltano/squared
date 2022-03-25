{{
    config(materialized='table')
}}

SELECT
    event_date,
    (
        SELECT COUNT(DISTINCT d2.project_id)
        FROM (

            SELECT DISTINCT
                fact_cli_events.event_date,
                fact_cli_events.project_id
            FROM {{ ref('fact_cli_events') }}
        ) AS d2
        WHERE
            d2.event_date BETWEEN DATEADD(
                DAY, -28, d.event_date
            ) AND d.event_date
    ) AS all_greater_0_life,
    (
        SELECT COUNT(DISTINCT d2.project_id)
        FROM (
            SELECT DISTINCT

                fact_cli_events.event_date,
                fact_cli_events.project_id
            FROM {{ ref('fact_cli_events') }}
            LEFT JOIN
                {{ ref('fact_cli_projects') }} ON
                    fact_cli_events.project_id = fact_cli_projects.project_id
            WHERE fact_cli_projects.exec_event_total > 1
        ) AS d2
        WHERE
            d2.event_date BETWEEN DATEADD(
                DAY, -28, d.event_date
            ) AND d.event_date
    ) AS exec_greater_1_life,
    (
        SELECT COUNT(DISTINCT d2.project_id)
        FROM (
            SELECT DISTINCT

                fact_cli_events.event_date,
                fact_cli_events.project_id
            FROM {{ ref('fact_cli_events') }}
            LEFT JOIN
                {{ ref('fact_cli_projects') }} ON
                    fact_cli_events.project_id = fact_cli_projects.project_id
            WHERE fact_cli_projects.exec_event_total > 0
        ) AS d2
        WHERE
            d2.event_date BETWEEN DATEADD(
                DAY, -28, d.event_date
            ) AND d.event_date
    ) AS exec_greater_0_life,
    (
        SELECT COUNT(DISTINCT d2.project_id)
        FROM
            (
                SELECT
                    fact_cli_events.event_date,
                    fact_cli_events.project_id,
                    SUM(
                        CASE
                            WHEN
                                fact_cli_events.is_exec_event THEN fact_cli_events.event_count
                            ELSE 0
                        END
                    ) AS exec_count
                FROM {{ ref('fact_cli_events') }}
                GROUP BY 1, 2
            ) AS d2
        WHERE
            d2.event_date BETWEEN DATEADD(
                DAY, -28, d.event_date
            ) AND d.event_date
            AND d2.exec_count > 1
    ) AS exec_greater_1_monthly,
    (
        SELECT COUNT(DISTINCT d2.project_id)
        FROM
            (
                SELECT
                    fact_cli_events.event_date,
                    fact_cli_events.project_id,
                    SUM(
                        CASE
                            WHEN
                                fact_cli_events.is_exec_event THEN fact_cli_events.event_count
                            ELSE 0
                        END
                    ) AS exec_count
                FROM {{ ref('fact_cli_events') }}
                GROUP BY 1, 2
            ) AS d2
        WHERE
            d2.event_date BETWEEN DATEADD(
                DAY, -28, d.event_date
            ) AND d.event_date
            AND d2.exec_count > 0
    ) AS exec_greater_0_monthly,
    (
        SELECT COUNT(DISTINCT d2.project_id)
        FROM
            (
                SELECT
                    fact_cli_events.event_date,
                    fact_cli_events.project_id,
                    COUNT(DISTINCT
                        CASE
                            WHEN
                                fact_cli_events.is_pipeline_exec_event THEN fact_cli_events.command
                        END
                    ) AS pipeline_count
                FROM {{ ref('fact_cli_events') }}
                GROUP BY 1, 2
            ) AS d2
        WHERE
            d2.event_date BETWEEN DATEADD(
                DAY, -28, d.event_date
            ) AND d.event_date
            AND d2.pipeline_count > 1
    ) AS unique_pipe_greater_1_monthly
FROM (
    SELECT DISTINCT event_date FROM {{ ref('fact_cli_events') }}
) AS d
