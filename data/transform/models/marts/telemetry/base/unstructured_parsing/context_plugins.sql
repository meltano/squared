WITH base AS (

    SELECT
        context.*,
        event_unstruct.event_id,
        context.value:schema::STRING AS schema_name
    FROM {{ ref('event_unstruct') }},
        LATERAL FLATTEN(
            input => PARSE_JSON(event_unstruct.contexts::VARIANT):data
        ) AS context
    WHERE
        context.value:schema LIKE 'iglu:com.meltano/plugins_context/%'
        AND event_unstruct.contexts IS NOT NULL

),

min_index AS (

    SELECT
        base.event_id,
        MIN(base.index) AS first_index
    FROM base
    GROUP BY 1

),

base_parsed AS (

    SELECT
        base.event_id,
        SPLIT_PART(base.schema_name, '/', -1) AS schema_version,
        base.value:data:plugins::STRING AS plugin_block,
        (base.index - min_index.first_index)::STRING AS plugin_index
    FROM base
    LEFT JOIN min_index ON base.event_id = min_index.event_id

)

SELECT
    event_id,
    schema_version,
    OBJECT_AGG(plugin_index, plugin_block::VARIANT) AS plugins_obj
FROM base_parsed
GROUP BY 1, 2
