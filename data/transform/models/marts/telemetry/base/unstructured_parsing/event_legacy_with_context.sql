-- These are events that were sent during the transistion from
-- structured to unstructured events. They are structured but
-- have context. They were >2.0 launch but didnt get transisted
-- to unstructured yet i.e. schedule, discover, state, etc. were
-- slowly migrated across a few releases. They arent included in
-- structured models so need to be included in unstruct.

SELECT
    event_id,
    'legacy' AS event_name,
    event_created_at,
    user_ipaddress,
    legacy_se_category,
    legacy_se_action,
    legacy_se_label
FROM {{ ref('event_unstruct') }}
WHERE event_name = 'event'
