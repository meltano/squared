-- All contexts from contexts_base should arrive in one of the
-- parsed tables.
SELECT
    event_id,
    schema_name
FROM {{ ref('context_base') }}
WHERE schema_name
    != 'iglu:com.snowplowanalytics.snowplow/web_page/jsonschema/1-0-0'

MINUS

SELECT * FROM (
    SELECT
        event_id,
        schema_name
    FROM {{ ref('context_cli') }}

    UNION ALL

    SELECT
        event_id,
        schema_name
    FROM {{ ref('context_environment') }}

    UNION ALL

    SELECT
        event_id,
        schema_name
    FROM {{ ref('context_exception') }}

    UNION ALL

    SELECT
        event_id,
        schema_name
    FROM {{ ref('context_plugins') }}

    UNION ALL

    SELECT
        event_id,
        schema_name
    FROM {{ ref('context_project') }}

    UNION ALL

    SELECT
        event_id,
        schema_name
    FROM {{ ref('context_identify') }}
)
