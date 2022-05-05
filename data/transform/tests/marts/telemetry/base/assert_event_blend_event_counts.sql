-- Assert event categories counts in the blended events table are >= the raw
-- GA counts. Some events come through more in Snowplow so its better to assert
-- at the category level to not allow one category to overwhelm the comparison.
WITH ga_counts AS (
    SELECT
        command_category,
        SUM(event_count) AS ga_event_count
    FROM {{ ref('stg_ga__cli_events') }}
    GROUP BY 1
),

blended_counts AS (
    SELECT
        command_category,
        SUM(event_count) AS blended_event_count
    FROM {{ ref('events_blended') }}
    GROUP BY 1
),

test AS (

    SELECT
        blended_counts.blended_event_count,
        ga_counts.ga_event_count,
        blended_counts.command_category
    FROM blended_counts
    LEFT JOIN ga_counts
        ON blended_counts.command_category = ga_counts.command_category

)

SELECT *
FROM test
WHERE ga_event_count > blended_event_count
