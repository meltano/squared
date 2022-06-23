-- count all structured events
-- count all unstructured events rolled up to execution id/project, where they arent already counted in structured events
-- sum the 2

-- pre 2.0 - structured + no context
-- post 2.0 - structured + context, unstructured + context

WITH snow_v2 AS (

    SELECT
        execution_mapping.project_id,
        DATE_TRUNC('WEEK', event_created_date) AS event_week_start_date,
        COUNT(distinct execution_mapping.execution_id) AS events
    FROM {{ ref('stg_snowplow__events') }}
    LEFT JOIN {{ ref('execution_mapping') }}
        ON stg_snowplow__events.event_id = execution_mapping.event_id
    where 
    event_name != 'telemetry_state_change_event'
    -- allow only struct events through that have execution ID that we can tie out with unstruct
    and execution_mapping.execution_id is not null
    -- TODO: add filters to exclude exit codes so failed events arent over populating
    group by 1,2

),
snow_pre_v2 AS (

    SELECT
        se_label AS project_id,
        DATE_TRUNC('WEEK', event_created_date) AS event_week_start_date,
        COUNT(distinct event_id) AS events
    FROM
        {{ ref('stg_snowplow__events') }}
    WHERE contexts is null
    and event = 'struct'
    group by 1,2

),

prep_snow AS (

    SELECT
        COALESCE(snow_v2.project_id, snow_pre_v2.project_id) AS project_id,
        DATE_TRUNC('WEEK', COALESCE(snow_v2.event_week_start_date, snow_pre_v2.event_week_start_date)) AS event_week_start_date,
        COALESCE(snow_v2.events, 0) + COALESCE(snow_pre_v2.events,0) AS events
    FROM
        snow_v2
    FULL JOIN snow_pre_v2
        on snow_v2.project_id = snow_pre_v2.project_id
        and snow_v2.event_week_start_date = snow_pre_v2.event_week_start_date

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
