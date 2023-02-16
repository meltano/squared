{{
    config(
        materialized='table'
    )
}}

WITH base_1_0_0 AS (
    SELECT
        event_id,
        MAX(event_created_at) AS event_created_at,
        MAX(schema_name) AS schema_name,
        MAX(context:data:command::STRING) AS command,
        MAX(context:data:sub_command::STRING) AS sub_command,
        OBJECT_AGG('legacy', context:data:option_keys) AS options_obj,
        MAX(SPLIT_PART(schema_name, '/', -1)) AS schema_version
    FROM {{ ref('context_base') }}
    WHERE schema_name = 'iglu:com.meltano/cli_context/jsonschema/1-0-0'
    GROUP BY 1
),

base_1_1_0_onward AS (
    SELECT
        event_id,
        MAX(event_created_at) AS event_created_at,
        MAX(context:schema::STRING) AS schema_name,
        MAX(
            CASE WHEN
                context:data:command::STRING != 'cli'
                AND COALESCE(
                    context:data:parent_command_hint,
                    'cli'
                ) = 'cli'
                THEN context:data:command::STRING END
        ) AS command,
        MAX(
            CASE WHEN
                context:data:command::STRING != 'cli'
                AND COALESCE(
                    context:data:parent_command_hint,
                    'cli'
                ) != 'cli'
                THEN context:data:command::STRING END
        ) AS sub_command,
        OBJECT_AGG(context:data:command, context:data:options) AS options_obj,
        MAX(SPLIT_PART(schema_name, '/', -1)) AS schema_version
    FROM {{ ref('context_base') }}
    WHERE
        schema_name LIKE 'iglu:com.meltano/cli_context/%'
        AND schema_name != 'iglu:com.meltano/cli_context/jsonschema/1-0-0'
    GROUP BY 1

)

SELECT *
FROM base_1_0_0

UNION ALL

SELECT *
FROM base_1_1_0_onward
