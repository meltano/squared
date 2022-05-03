-- Assert all counts for critical event categories in the Snowplow/GA
-- blended events table are >= the raw GA counts
WITH ga_counts AS (
    SELECT
        SUM(event_count) AS ga_event_count,
        command_category
    FROM {{ ref('stg_ga__cli_events') }}
    WHERE command_category IN (
        'meltano invoke',
        'meltano elt',
        'meltano run',
        'meltano test',
        'meltano ui',
        'meltano install',
        'meltano init'
    ) OR command LIKE 'meltano schedule run%'
    GROUP BY 2
),
snow_blended_counts AS (
    SELECT
        SUM(event_count) AS snow_event_count,
        command_category
    FROM {{ ref('events_blended') }}
    WHERE command_category IN (
        'meltano invoke',
        'meltano elt',
        'meltano run',
        'meltano test',
        'meltano ui',
        'meltano install',
        'meltano init'
    ) OR command LIKE 'meltano schedule run%'
    GROUP BY 2
),
test AS (

    SELECT
        snow_blended_counts.snow_event_count,
        ga_counts.ga_event_count
    FROM snow_blended_counts
    LEFT JOIN ga_counts
        ON snow_blended_counts.command_category = ga_counts.command_category

)
SELECT *
FROM test
WHERE ga_event_count > snow_event_count
