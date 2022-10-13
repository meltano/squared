WITH base AS (

    SELECT
        context,
        event_id,
        schema_name,
        context_index
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
        schema_name,
        SPLIT_PART(base.schema_name, '/', -1) AS schema_version,
        base.context:data:plugins::STRING AS plugin_block,
        (base.context_index - min_index.first_index)::STRING AS plugin_index
    FROM base
    LEFT JOIN min_index ON base.event_id = min_index.event_id

)

SELECT
    event_id,
    schema_name,
    schema_version,
    OBJECT_AGG(plugin_index, plugin_block::VARIANT) AS plugins_obj
FROM base_parsed
GROUP BY 1, 2, 3
