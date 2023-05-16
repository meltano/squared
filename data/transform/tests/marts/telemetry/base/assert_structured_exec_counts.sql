-- Assert event categories counts in the structured executions table are >= the
-- raw GA counts. Some events come through more in Snowplow so its better to
-- assert at the category level to not allow one category to overwhelm the
-- comparison.
WITH ga_counts AS (
    SELECT
        command_category,
        SUM(event_count) AS ga_event_count
    FROM {{ ref('stg_ga__cli_events') }}
    GROUP BY 1
),

struct_counts AS (
    SELECT
        command_category,
        SUM(event_count) AS struct_event_count
    FROM {{ ref('structured_executions') }}
    GROUP BY 1
),

test AS (

    SELECT
        struct_counts.struct_event_count,
        ga_counts.ga_event_count,
        struct_counts.command_category
    FROM struct_counts
    LEFT JOIN ga_counts
        ON struct_counts.command_category = ga_counts.command_category

)

SELECT
    *,
    100 * ((ga_event_count - struct_event_count) / ga_event_count) AS diff_pct
FROM test
WHERE
    ga_event_count > struct_event_count
    -- These are slightly off but are vs exec events
    AND command_category NOT LIKE 'meltano add %'
    AND command_category != 'meltano select'
    AND diff_pct > 0.5
