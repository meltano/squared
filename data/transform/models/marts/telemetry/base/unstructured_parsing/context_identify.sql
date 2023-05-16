{{
    config(
        materialized='table'
    )
}}

WITH base AS (

    SELECT
        event_id,
        MAX(event_created_at) AS event_created_at,
        MAX(schema_name) AS schema_name,
        MAX(
            context:data:leadmagic_company_name::STRING
        ) AS leadmagic_company_name,
        MAX(
            context:data:leadmagic_company_domain::STRING
        ) AS leadmagic_company_domain
    FROM {{ ref('context_base') }}
    WHERE
        schema_name LIKE 'iglu:com.meltano/identify_context/%'
    GROUP BY 1

)

SELECT
    *,
    SPLIT_PART(schema_name, '/', -1) AS schema_version
FROM base
