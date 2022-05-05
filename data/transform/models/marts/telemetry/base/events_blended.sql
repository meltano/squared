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
),

to_blend AS (

    SELECT
        prep_snow.project_id,
        MIN(prep_snow.event_week_start_date) AS sp_activate_date
    FROM prep_snow
    LEFT JOIN prep_ga ON prep_snow.project_id = prep_ga.project_id
        AND prep_snow.event_week_start_date = prep_ga.event_week_start_date
    WHERE COALESCE(100 * (prep_snow.events * 1.0 / prep_ga.events), 100) >= 100
    GROUP BY 1

),

blended AS (
    SELECT
        'snowplow' AS event_source,
        1 AS event_count,
        stg_snowplow__events.se_category AS command_category,
        stg_snowplow__events.se_action AS command,
        stg_snowplow__events.se_label AS project_id,
        stg_snowplow__events.event_id,
        stg_snowplow__events.event_created_at,
        stg_snowplow__events.event_created_date
    FROM {{ ref('stg_snowplow__events') }}
    INNER JOIN
        to_blend ON
            stg_snowplow__events.se_label = to_blend.project_id
    WHERE
        stg_snowplow__events.event_created_date >= to_blend.sp_activate_date

    UNION

    SELECT
        'ga' AS event_source,
        stg_ga__cli_events.event_count,
        stg_ga__cli_events.command_category,
        stg_ga__cli_events.command,
        stg_ga__cli_events.project_id,
        stg_ga__cli_events.event_surrogate_key,
        stg_ga__cli_events.event_date,
        stg_ga__cli_events.event_date
    FROM {{ ref('stg_ga__cli_events') }}
    LEFT JOIN
        to_blend ON
            stg_ga__cli_events.project_id = to_blend.project_id
    WHERE
        to_blend.sp_activate_date IS NULL
        OR stg_ga__cli_events.event_date < to_blend.sp_activate_date
)

SELECT * FROM blended
