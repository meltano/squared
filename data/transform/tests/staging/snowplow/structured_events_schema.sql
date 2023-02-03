-- We hardcode google analytics schemas for reparsing bad events in
-- `snowplow_bad_parsed` assuming theres only one event schema. If
-- that changes we should be alerted.
SELECT DISTINCT
    event_vendor,
    event_name,
    event_format,
    event_version
FROM {{ ref('stg_snowplow__events') }}
WHERE event_vendor = 'com.google.analytics'
    AND event_version != '1-0-0'
