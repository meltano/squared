{{
    config(materialized='table')
}}

WITH exec_projects AS (
    SELECT
        project_id,
        SUM(
            CASE
                WHEN
                    command_category IN (
                        'meltano elt',
                        'meltano invoke',
                        'meltano run',
                        'meltano test',
                        'meltano ui'
                    ) THEN event_count
                ELSE 0
            END
        ) AS exec_count
    FROM {{ ref('fact_cli_events') }}
    GROUP BY 1
)

SELECT
    event_date,
    (
        SELECT COUNT(DISTINCT project_id)
        FROM (

            SELECT DISTINCT
                event_date,
                project_id
            FROM {{ ref('stg_ga__cli_events') }}
        ) AS d2
        WHERE
            d2.event_date BETWEEN DATEADD(
                DAY, -28, d.event_date
            ) AND d.event_date
    ) AS all_greater_0_life,
    (
        SELECT COUNT(DISTINCT project_id)
        FROM (
            SELECT DISTINCT

                stg_ga__cli_events.event_date,
                stg_ga__cli_events.project_id
            FROM {{ ref('stg_ga__cli_events') }}
            LEFT JOIN
                exec_projects ON
                    stg_ga__cli_events.project_id = exec_projects.project_id
            WHERE exec_projects.exec_count > 1
        ) AS d2
        WHERE
            d2.event_date BETWEEN DATEADD(
                DAY, -28, d.event_date
            ) AND d.event_date
    ) AS exec_greater_1_life,
    (
        SELECT COUNT(DISTINCT project_id)
        FROM (
            SELECT DISTINCT

                stg_ga__cli_events.event_date,
                stg_ga__cli_events.project_id
            FROM {{ ref('stg_ga__cli_events') }}
            LEFT JOIN
                exec_projects ON
                    stg_ga__cli_events.project_id = exec_projects.project_id
            WHERE exec_projects.exec_count > 0
        ) AS d2
        WHERE
            d2.event_date BETWEEN DATEADD(
                DAY, -28, d.event_date
            ) AND d.event_date
    ) AS exec_greater_0_life,
    (
        SELECT COUNT(DISTINCT project_id)
        FROM
            (
                SELECT
                    stg_ga__cli_events.event_date,
                    stg_ga__cli_events.project_id,
                    SUM(
                        CASE
                            WHEN
                                command_category IN (
                                    'meltano elt',
                                    'meltano invoke',
                                    'meltano run',
                                    'meltano test',
                                    'meltano ui'
                                ) THEN event_count
                            ELSE 0
                        END
                    ) AS exec_count
                FROM {{ ref('stg_ga__cli_events') }}
                GROUP BY 1, 2
            ) AS d2
        WHERE
            d2.event_date BETWEEN DATEADD(
                DAY, -28, d.event_date
            ) AND d.event_date
            AND d2.exec_count > 1
    ) AS exec_greater_1_monthly,
    (
        SELECT COUNT(DISTINCT project_id)
        FROM
            (
                SELECT
                    stg_ga__cli_events.event_date,
                    stg_ga__cli_events.project_id,
                    SUM(
                        CASE
                            WHEN
                                command_category IN (
                                    'meltano elt',
                                    'meltano invoke',
                                    'meltano run',
                                    'meltano test',
                                    'meltano ui'
                                ) THEN event_count
                            ELSE 0
                        END
                    ) AS exec_count
                FROM {{ ref('stg_ga__cli_events') }}
                GROUP BY 1, 2
            ) AS d2
        WHERE
            d2.event_date BETWEEN DATEADD(
                DAY, -28, d.event_date
            ) AND d.event_date
            AND d2.exec_count > 0
    ) AS exec_greater_0_monthly,
    (
        SELECT COUNT(DISTINCT project_id)
        FROM
            (
                SELECT
                    stg_ga__cli_events.event_date,
                    stg_ga__cli_events.project_id,
                    COUNT(DISTINCT
                        CASE
                            WHEN
                                command_category IN (
                                    'meltano elt',
                                    'meltano invoke',
                                    'meltano run'
                                ) THEN command
                        END
                    ) AS pipeline_count
                FROM {{ ref('stg_ga__cli_events') }}
                GROUP BY 1, 2
            ) AS d2
        WHERE
            d2.event_date BETWEEN DATEADD(
                DAY, -28, d.event_date
            ) AND d.event_date
            AND d2.pipeline_count > 1
    ) AS unique_pipe_greater_1_monthly
FROM (
    SELECT DISTINCT event_date FROM {{ ref('stg_ga__cli_events') }}
) AS d
