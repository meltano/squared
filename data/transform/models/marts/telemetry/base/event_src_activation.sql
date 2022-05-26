WITH prep_snow AS (

    SELECT
        se_label AS project_id,
        DATE_TRUNC('WEEK', event_created_date) AS event_week_start_date,
        COUNT(event_id) AS events
    FROM
        {{ ref('stg_snowplow__events') }}
    GROUP BY 1, 2
),

prep_ga AS (

    SELECT
        project_id,
        DATE_TRUNC('WEEK', event_date) AS event_week_start_date,
        SUM(event_count) AS events
    FROM {{ ref('stg_ga__cli_events') }}
    GROUP BY 1, 2
)

SELECT
    prep_snow.project_id,
    MIN(prep_snow.event_week_start_date) AS sp_activate_date
FROM prep_snow
LEFT JOIN prep_ga ON prep_snow.project_id = prep_ga.project_id
    AND prep_snow.event_week_start_date = prep_ga.event_week_start_date
WHERE COALESCE(100 * (prep_snow.events * 1.0 / prep_ga.events), 100) >= 100
GROUP BY 1
