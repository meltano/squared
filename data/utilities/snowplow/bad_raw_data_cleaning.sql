-- Invalid json with escape character
SELECT CHECK_JSON(contexts::VARIANT) AS test, *
FROM RAW.snowplow.events
WHERE CHECK_JSON(contexts::VARIANT) IS NOT NULL;

DELETE FROM RAW.snowplow.events WHERE event_id IN  (
    'e0a03077-d979-4d9f-8972-2912a836be00',
    'e45332af-290b-4a01-a419-82fe7d0aa682',
    'ba93ff23-480c-4d5e-aada-d9c0080f9d14'
);

-- tab in struct event leads to bad timestamp
DELETE FROM RAW.snowplow.events WHERE event_id = '3abd7aac-fa66-4922-b72e-5d4c27e7a50d';
