WITH active_projects AS (

    SELECT
        structured_events.project_id
    FROM USERDEV_PREP.PNADOLNY_WORKSPACE.structured_events
    LEFT JOIN USERDEV_PREP.PNADOLNY_WORKSPACE.structured_parsing_combined on structured_events.command = structured_parsing_combined.command
    WHERE structured_parsing_combined.command_category IN (
        'meltano invoke',
        'meltano elt',
        'meltano run',
        'meltano ui',
        'meltano test',
        'meltano schedule run'
    )
    AND structured_events.event_created_at >= DATEADD('month',  -1, current_date())
    GROUP BY 1
    HAVING SUM(structured_events.event_count) > 1

)
SELECT
    structured_events.project_id,
    MAX(CASE WHEN active_projects.project_id IS NOT NULL THEN TRUE END) AS is_active,
    MIN(event_created_at) AS first_event_at,
    MAX(event_created_at) AS last_event_at
FROM {{ ref('structured_events') }}
LEFT JOIN {{ ref('structured_parsing_combined') }} on structured_events.command = structured_parsing_combined.command
LEFT JOIN active_projects ON structured_events.project_id = active_projects.project_id
GROUP BY 1
