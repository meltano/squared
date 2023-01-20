with base as (
    select
        case when startswith(log_message, '(') then SUBSTR(log_message, 40, 10000000) else log_message end as payload,
        case when startswith(log_message, '(') then SUBSTR(log_message, 2, 36) else parse_json(payload):requestId end as request_id,
        case when startswith(payload, 'Method') then split_part(payload, ':', 1) end as method_type,
        case when startswith(payload, 'Method') then ARRAY_TO_STRING(ARRAY_SLICE(split(payload, ':'), 1,100000000), ':') end as method_body,
        REPLACE(split_part(split_part(payload, 'User-Agent=', 2), ',',1), 'Meltano/', '') AS meltano_version,
     	split_part(split_part(payload, 'X-Project-ID=', 2), ', ', 1) AS project_id,
     	case when startswith(payload, '{') then parse_json(payload):ip::string end as ip_address,
        -- TODO: this isnt perfect, still get some other random stuff
     	case when startswith(payload, 'HTTP Method: GET, Resource Path') then split_part(payload, ': ', 3) end as request_path,
     	ARRAY_SLICE(
    		split(
    			split_part(
    				split_part(payload, 'X-Forwarded-For=', 2),
    				'=', 1
    			), ', '
    		),
    		0, -1
    	) AS ip_address_array,
        *
    from {{ ref('stg_cloudwatch__log')}}
),
request_rollup as (
    select
        request_id,
        max(meltano_version) as meltano_version,
        max(project_id) as project_id,
        max(ip_address) as ip_address
    from base
    group by 1

)
select
    base.payload,
    base.request_id,
    base.method_type,
    base.method_body,
    base.request_path,
    request_rollup.meltano_version,
    request_rollup.project_id,
    request_rollup.ip_address,
    base.log_message
from base
    left join request_rollup on base.request_id = request_rollup.request_id