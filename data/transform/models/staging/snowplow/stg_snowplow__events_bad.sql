SELECT
    uploaded_at,
    jsontext
    {% if env_var("MELTANO_ENVIRONMENT") == "cicd" %}

FROM raw.snowplow.events_bad
WHERE uploaded_at::TIMESTAMP >= DATEADD('day', -7, CURRENT_DATE)
{% else %}

    FROM {{ source('snowplow', 'events_bad') }}

    {% endif %}
