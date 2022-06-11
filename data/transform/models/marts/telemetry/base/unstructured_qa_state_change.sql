select
    event_id,
    event_name,
    DVCE_CREATED_TSTAMP::TIMESTAMP AS DVCE_CREATED_TSTAMP,
    USER_IPADDRESS,
    max(parse_json(unstruct_event::variant):data:data:setting_name::string) as setting_name,
    max(parse_json(unstruct_event::variant):data:data:changed_from::string) as changed_from,
    max(parse_json(unstruct_event::variant):data:data:changed_to::string) as changed_to
from RAW.SNOWPLOW.EVENTS
where event = 'unstruct'
and event_name = 'telemetry_state_change_event'
group by 1,2,3,4
