-- ELT Taps
SELECT
    event_created_date AS event_date,
    project_id,
    event_count,
    SPLIT_PART(command, ' ', 3) AS plugin_name,
    'tap' AS plugin_type,
    command_category
FROM {{ ref('events_blended') }}
WHERE command_category = 'meltano elt'

UNION ALL

-- ELT Targets
SELECT
    event_created_date AS event_date,
    project_id,
    event_count,
    SPLIT_PART(command, ' ', 4) AS plugin_name,
    'target' AS plugin_type,
    command_category
FROM {{ ref('events_blended') }}
WHERE command_category = 'meltano elt'

UNION ALL

-- Invoke Taps
SELECT
    event_created_date AS event_date,
    project_id,
    event_count,
    SPLIT_PART(command, ' ', 3) AS plugin_name,
    'tap' AS plugin_type,
    command_category
FROM {{ ref('events_blended') }}
WHERE command_category = 'meltano invoke'
    AND SPLIT_PART(command, ' ', 3) LIKE 'tap%'

UNION ALL

-- Invoke Targets
SELECT
    event_created_date AS event_date,
    project_id,
    event_count,
    SPLIT_PART(command, ' ', 3) AS plugin_name,
    'target' AS plugin_type,
    command_category
FROM {{ ref('events_blended') }}
WHERE command_category = 'meltano invoke'
    AND SPLIT_PART(command, ' ', 3) LIKE 'target%'
