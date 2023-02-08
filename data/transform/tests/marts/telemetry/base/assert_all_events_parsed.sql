-- All events from event_unstruct should arrive in one of the
-- parsed tables.
SELECT DISTINCT event_id FROM {{ ref('event_unstruct') }}
-- page views are parsed by the snowplow dbt package
WHERE event != 'page_view'
MINUS
SELECT DISTINCT event_id FROM {{ ref('event_block') }}
MINUS
SELECT DISTINCT event_id FROM {{ ref('event_cli') }}
MINUS
SELECT DISTINCT event_id FROM {{ ref('event_exit') }}
MINUS
SELECT DISTINCT event_id FROM {{ ref('event_legacy_with_context') }}
MINUS
SELECT DISTINCT event_id FROM {{ ref('event_telemetry_state_change') }}
