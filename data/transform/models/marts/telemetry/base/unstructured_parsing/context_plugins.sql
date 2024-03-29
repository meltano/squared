{{
    config(
        materialized='table'
    )
}}

WITH base AS (

    SELECT
        context,
        event_id,
        schema_name,
        context_index,
        event_created_at
    FROM {{ ref('context_base') }}
    WHERE
        schema_name LIKE 'iglu:com.meltano/plugins_context/%'

),

min_index AS (

    SELECT
        base.event_id,
        MIN(base.context_index) AS first_index
    FROM base
    GROUP BY 1

),

base_parsed AS (

    SELECT
        base.event_id,
        base.event_created_at,
        base.schema_name,
        (base.context_index - min_index.first_index)::STRING AS plugin_index,
        SPLIT_PART(base.schema_name, '/', -1) AS schema_version,
        base.context:data:plugins AS plugin_block
    FROM base
    LEFT JOIN min_index ON base.event_id = min_index.event_id

)

SELECT
    event_id,
    event_created_at,
    schema_name,
    schema_version,
    -- TODO: Use a dict here to avoid deduping
    ARRAY_AGG(DISTINCT plugin_block) AS plugins_obj
FROM base_parsed
GROUP BY 1, 2, 3, 4
