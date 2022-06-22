select
    event_id,
    max(case when context.value:schema::string like 'iglu:com.meltano/project_context/jsonschema/%' then context.value:data:context_uuid::string end) as execution_id
FROM {{ ref('stg_snowplow__events') }},
LATERAL FLATTEN(input => COALESCE(parse_json(contexts::variant):data, [''])) as context
-- WHERE event = 'unstruct'
group by 1
