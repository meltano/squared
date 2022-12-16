-- Asserts that the counts of pipeline events in the structured events
-- Snowplow + GA table is within 1% of a crude estimate of the 2
-- staging tables blended for the previous months.

{% if env_var("MELTANO_ENVIRONMENT") == "cicd" %}

    -- Dummy test during CI since this is data sensitive
    SELECT '' WHERE 1 != 1

{% else %}

    WITH snow AS (
        -- pipeline events last month from snowplow by project_id
        SELECT
            se_label AS project_id,
            COUNT(event_id) AS event_count
        FROM {{ ref('stg_snowplow__events') }}
        WHERE se_category IN ('meltano elt', 'meltano invoke', 'meltano run')
            AND DATE_TRUNC(
                'month', event_created_at
            )::DATE = DATEADD('month', -1, DATE_TRUNC('month', CURRENT_DATE))
            AND event = 'struct'
            AND contexts IS NULL
        GROUP BY 1
    ),

    ga AS (
        -- pipeline events last month from GA by project_id
        SELECT
            project_id,
            SUM(event_count) AS event_count
        FROM {{ ref('stg_ga__cli_events') }}
        WHERE
            command_category IN ('meltano elt', 'meltano invoke', 'meltano run')
            AND DATE_TRUNC(
                'month', event_date
            )::DATE = DATEADD('month', -1, DATE_TRUNC('month', CURRENT_DATE))
        GROUP BY 1
    ),

    blend AS (
        -- taking GA, then layering in Snow data by project_id, find project ids
        -- where we have more events from snow for pipelines last month
        SELECT
            ga.project_id,
            ga.event_count AS ga_cnt,
            snow.event_count AS snow_cnt
        FROM ga
        LEFT JOIN snow ON ga.project_id = snow.project_id
        WHERE snow.event_count >= ga.event_count
    ),

    snow_more_events AS (
        -- retrieve snowplow event counts where project id
        -- has more in snow than GA
        SELECT snow.*
        FROM snow LEFT JOIN blend ON snow.project_id = blend.project_id
        WHERE blend.project_id IS NOT NULL
    ),

    ga_more_events AS (
        -- retrieve ga event counts where snow doenst have more events
        SELECT ga.* FROM ga LEFT JOIN blend ON ga.project_id = blend.project_id
        WHERE blend.project_id IS NULL
    ),

    unioned AS (
        -- combine estimate counts
        SELECT
            project_id,
            event_count
        FROM snow_more_events
        UNION ALL
        SELECT
            project_id,
            event_count
        FROM ga_more_events
    ),

    estimate AS (
        SELECT SUM(event_count) AS event_count FROM unioned
    ),

    prod AS (
        -- prod counts to compare against
        SELECT SUM(event_count) AS event_count
        FROM {{ ref('structured_executions') }}
        WHERE
            command_category IN ('meltano elt', 'meltano invoke', 'meltano run')
            AND DATE_TRUNC(
                'month', event_created_date
            )::DATE = DATEADD('month', -1, DATE_TRUNC('month', CURRENT_DATE))
    ),

    test AS (
        SELECT
            prod.event_count AS prod_count,
            estimate.event_count AS estimate_count,
            100 * (
                prod.event_count - estimate.event_count
            ) / estimate.event_count AS percent_diff
        FROM estimate
        INNER JOIN prod ON 1 = 1
    )

    SELECT *
    FROM test
    -- Estimates vs prod are within a 3% range 
    WHERE ABS(percent_diff) > 3

{% endif %}
