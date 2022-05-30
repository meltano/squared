WITH active_events AS (
    SELECT
        structured_events.project_id,
        structured_events.event_created_at,
        structured_events.event_count
    FROM {{ ref('structured_events') }}
    LEFT JOIN
        {{ ref('cmd_parsed_all') }} ON
            structured_events.command = cmd_parsed_all.command
    WHERE cmd_parsed_all.command_category IN (
        'meltano invoke',
        'meltano elt',
        'meltano run',
        'meltano ui',
        'meltano test',
        'meltano schedule run'
    )
),

active_projects AS (

    SELECT
        project_id,
        DATE_TRUNC('month', event_created_at) AS month_start,
        SUM(event_count) AS active_events_count
    FROM active_events
    GROUP BY 1, 2

),

active_profile AS (

    SELECT
        structured_events.project_id,
        MIN(structured_events.event_created_at) AS activation_at,
        MAX(structured_events.event_created_at) AS last_active_at
    FROM {{ ref('structured_events') }}
    INNER JOIN active_projects
        ON structured_events.project_id = active_projects.project_id
            AND DATE_TRUNC(
                'month', structured_events.event_created_at
            ) = active_projects.month_start
    WHERE active_projects.active_events_count > 1
    GROUP BY 1

)

SELECT
    structured_events.project_id,
    MAX(active_profile.activation_at) AS activation_date,
    MAX(active_profile.last_active_at) AS last_activate_at,
    MIN(structured_events.event_created_at) AS first_event_at,
    MAX(structured_events.event_created_at) AS last_event_at
FROM {{ ref('structured_events') }}
LEFT JOIN
    active_profile ON structured_events.project_id = active_profile.project_id
GROUP BY 1
