WITH base AS (

    SELECT
        unstruct_event_flattened.execution_id,
        unstruct_event_flattened.plugins_obj,
        unstruct_exec_flattened.cli_command,
        MAX(exception) AS exception_dict,
        MAX(unstruct_event_flattened.event_created_at) AS plugin_started,
        MIN(unstruct_event_flattened.event_created_at) AS plugin_ended,
        MAX(unstruct_event_flattened.block_type) AS block_type,
        ARRAY_AGG(unstruct_event_flattened.event) AS event_statuses
    FROM {{ ref('unstruct_event_flattened') }}
    LEFT JOIN {{ ref('unstruct_exec_flattened') }}
        ON
            unstruct_event_flattened.execution_id = unstruct_exec_flattened.execution_id
    GROUP BY 1, 2, 3

),

flattened AS (
    SELECT
        {{ dbt_utils.surrogate_key(
            [
                'plugin.value',
                'base.execution_id',
                'base.plugin_started',
                'plugin.index'
            ]
        ) }} AS plugin_exec_block_pk,
        {{ dbt_utils.surrogate_key(
            ['plugin.value']
        ) }} AS plugin_surrogate_key,
        base.execution_id,
        base.plugins_obj,
        base.cli_command,
        base.plugin_started,
        base.plugin_ended,
        base.block_type,
        base.event_statuses,
        base.exception_dict,
        plugin.value AS plugin_definition,
        GET(plugin.value::VARIANT, 'category')::STRING AS plugin_category
    FROM base,
        LATERAL FLATTEN(
            input => PARSE_JSON(GET(plugins_obj, '0'))
        ) AS plugin
    WHERE base.plugins_obj IS NOT NULL
),

incomplete_plugins AS (

    SELECT
        flattened.plugin_exec_block_pk,
        flattened.execution_id,
        exception_dict,
        h1.unhashed_value AS top_runtime_error,
        h2.unhashed_value AS nested_runtime_error,
        GET(
            PARSE_JSON(exception_dict), 'str_hash'
        )::STRING AS hashed_runtime_error,
        GET(
            GET(PARSE_JSON(exception_dict), 'cause')::VARIANT, 'str_hash'
        )::STRING AS hashed_nested_runtime_error
    FROM flattened
    LEFT JOIN {{ ref('hash_lookup') }} AS h1
        ON GET(PARSE_JSON(exception_dict), 'str_hash')::STRING = h1.hash_value
            AND h1.category = 'runtime_error'
    LEFT JOIN {{ ref('hash_lookup') }} AS h2
        ON
            GET(
                GET(PARSE_JSON(exception_dict), 'cause')::VARIANT, 'str_hash'
            )::STRING = h2.hash_value
            AND h2.category = 'runtime_error'
    WHERE NOT ARRAY_CONTAINS('completed'::VARIANT, flattened.event_statuses)

),

exception_mapping AS (

    SELECT * FROM (
        VALUES ('Loader failed', 'loaders'), ('Extractor failed', 'extractors'),
        ('Mappers failed', 'mappers'), ('`dbt run` failed', 'transformers'),
        ('Extractor and loader failed', 'extractors'),
        (
            'Unexpected completion sequence in ExtractLoadBlock set. Intermediate block (likely a mapper) failed.',
            'mappers'
        ),
        (
            'Could not find catalog. Verify that the tap supports discovery mode and advertises the `discover` capability as well as either `catalog` or `properties`',
            'extractors'
        )
    ) AS v1 (runtime_error, category)

)

SELECT
    flattened.plugin_exec_block_pk,
    flattened.plugin_surrogate_key,
    flattened.execution_id,
    flattened.plugin_started,
    flattened.plugin_ended,
    flattened.block_type,
    flattened.event_statuses,
    flattened.plugin_category,
    flattened.exception_dict,
    flattened.plugin_definition,
    incomplete_plugins.top_runtime_error,
    incomplete_plugins.hashed_runtime_error,
    ex_map_top.category AS top_ex_plugin_category,
    ex_map_nested.category AS nested_ex_plugin_category,
    DATEDIFF(
        MILLISECOND, flattened.plugin_ended, flattened.plugin_started
    ) AS plugin_runtime_ms,
    CASE
        WHEN flattened.cli_command = 'elt' THEN
            CASE
                WHEN incomplete_plugins.execution_id IS NULL THEN 'SUCCESS'
                WHEN
                    NOT ARRAY_CONTAINS(
                        'failed'::VARIANT, flattened.event_statuses
                    ) THEN 'ABORTED-SKIPPED'
                WHEN
                    incomplete_plugins.hashed_nested_runtime_error IS NOT NULL AND ex_map_nested.runtime_error IS NULL THEN 'EXCEPTION_PARSING_FAILED'
                WHEN
                    flattened.plugin_category = ex_map_nested.category THEN 'FAILED'
                WHEN
                    flattened.plugin_category != ex_map_nested.category THEN 'INCOMPLETE_EL_PAIR'
                WHEN
                    incomplete_plugins.exception_dict IS NULL THEN 'NULL_EXCEPTION'
                ELSE 'OTHER_FAILURE'
            END
        WHEN flattened.cli_command = 'run' THEN
            CASE
                -- It had a completed event so it succeeded
                WHEN incomplete_plugins.execution_id IS NULL THEN 'SUCCESS'
                -- It never completed but also didnt have a failure, call it aborted or skipped.
                WHEN
                    NOT ARRAY_CONTAINS(
                        'failed'::VARIANT, flattened.event_statuses
                    ) THEN 'ABORTED-SKIPPED'
                -- We couldnt parse the exception enough to know which plugin in the EL block failed
                WHEN
                    flattened.block_type = 'ExtractLoadBlocks' AND incomplete_plugins.hashed_runtime_error IS NOT NULL AND ex_map_top.runtime_error IS NULL THEN 'EXCEPTION_PARSING_FAILED'
                -- EL Block, no exception to parse
                WHEN
                    flattened.block_type = 'ExtractLoadBlocks' AND incomplete_plugins.exception_dict IS NULL THEN 'NULL_EXCEPTION'
                -- EL block and parsed/unhashed exception matches this plugin category
                WHEN
                    flattened.block_type = 'ExtractLoadBlocks' AND flattened.plugin_category = ex_map_top.category THEN 'FAILED'
                -- EL block and parsed/unhashed exception doesnt match this plugin category, its not the reason but it also isnt successful
                WHEN
                    flattened.block_type = 'ExtractLoadBlocks' AND flattened.plugin_category != ex_map_top.category THEN 'INCOMPLETE_EL_PAIR'
                -- Invoker has only 1 plugin involved, safe to call it failed no matter what the exception was
                WHEN flattened.block_type = 'InvokerCommand' THEN 'FAILED'
                ELSE 'OTHER_FAILURE'
            END
        WHEN flattened.cli_command = 'invoke' THEN
            CASE
                -- It had a completed event so it succeeded
                WHEN incomplete_plugins.execution_id IS NULL THEN 'SUCCESS'
                -- It never completed but also didnt have a failure, call it aborted or skipped.
                WHEN
                    NOT ARRAY_CONTAINS(
                        'failed'::VARIANT, flattened.event_statuses
                    ) THEN 'ABORTED-SKIPPED'
                ELSE 'FAILED'
            END
    END AS completion_status
FROM flattened
LEFT JOIN incomplete_plugins
    ON flattened.plugin_exec_block_pk = incomplete_plugins.plugin_exec_block_pk
LEFT JOIN exception_mapping AS ex_map_top
    ON incomplete_plugins.top_runtime_error = ex_map_top.runtime_error
LEFT JOIN exception_mapping AS ex_map_nested
    ON incomplete_plugins.nested_runtime_error = ex_map_nested.runtime_error
WHERE flattened.cli_command IN ('elt', 'run', 'invoke')
