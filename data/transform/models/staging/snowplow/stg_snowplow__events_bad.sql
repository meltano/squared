SELECT
    uploaded_at,
    PARSE_JSON(jsontext):id::STRING AS id,
    PARSE_JSON(jsontext):account::STRING AS account_name,
    PARSE_JSON(jsontext):resources AS resources,
    PARSE_JSON(jsontext):time::TIMESTAMP AS event_time,
    PARSE_JSON(jsontext):source::STRING AS source,
    PARSE_JSON(jsontext):region::STRING AS region,
    PARSE_JSON(jsontext):version::STRING AS event_version,
    PARSE_JSON(jsontext):detail:schema::STRING AS failure_schema,
    PARSE_JSON(jsontext):detail:data:failure:messages AS failure_message,
    PARSE_JSON(
        jsontext
    ):detail:data:failure:messages[0]:error:error::STRING AS error,
    PARSE_JSON(
        jsontext
    ):detail:data:failure:timestamp::TIMESTAMP AS failure_timestamp,
    PARSE_JSON(jsontext):detail:data:payload:raw AS payload_raw,
    PARSE_JSON(jsontext):detail:data:payload:enriched AS payload_enriched,
    PARSE_JSON(jsontext):detail:data:processor AS processor
    {% if env_var("MELTANO_ENVIRONMENT") == "cicd" %}

FROM raw.snowplow.events_bad
WHERE uploaded_at::TIMESTAMP >= DATEADD('day', -7, CURRENT_DATE)
{% else %}

    FROM {{ source('snowplow', 'events_bad') }}

    {% endif %}
