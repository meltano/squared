-- SQLFluff fails because dbt_utils casts differently then us. Ignore for file.
-- noqa: disable=L067
WITH base AS (

    SELECT
        context_uuid AS execution_id,
        plugins_obj,
        command AS cli_command,
        MAX(exception) AS exception_dict,
        MIN(event_created_at) AS plugin_started,
        MAX(event_created_at) AS plugin_ended,
        MAX(block_type) AS block_type,
        ARRAY_AGG(event) AS event_statuses
    FROM {{ ref('unstruct_event_flattened') }}
    WHERE event_name != 'telemetry_state_change_event'
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
            -- TODO: this excludes non-index 0 plugins within a single event
            input => GET(plugins_obj, 0)
        ) AS plugin
    WHERE base.plugins_obj IS NOT NULL
),

incomplete_plugins AS (

    SELECT
        flattened.plugin_exec_block_pk,
        flattened.execution_id,
        flattened.exception_dict,
        h1.unhashed_value AS top_runtime_error,
        h2.unhashed_value AS nested_runtime_error,
        GET(
            PARSE_JSON(flattened.exception_dict), 'str_hash'
        )::STRING AS hashed_runtime_error,
        GET(
            GET(
                PARSE_JSON(flattened.exception_dict), 'cause'
            )::VARIANT,
            'str_hash'
        )::STRING AS hashed_nested_runtime_error
    FROM flattened
    LEFT JOIN {{ ref('hash_lookup') }} AS h1
        ON GET(
            PARSE_JSON(flattened.exception_dict),
            'str_hash'
        )::STRING = h1.hash_value
        AND h1.category = 'runtime_error'
    LEFT JOIN {{ ref('hash_lookup') }} AS h2
        ON
            GET(
                GET(
                    PARSE_JSON(flattened.exception_dict),
                    'cause'
                )::VARIANT, 'str_hash'
            )::STRING = h2.hash_value
            AND h2.category = 'runtime_error'
    WHERE NOT ARRAY_CONTAINS('completed'::VARIANT, flattened.event_statuses)

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
    ex_map_top.plugin_category AS top_ex_plugin_category,
    ex_map_nested.plugin_category AS nested_ex_plugin_category,
    DATEDIFF(
        MILLISECOND, flattened.plugin_started, flattened.plugin_ended
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
                    incomplete_plugins.hashed_nested_runtime_error IS NOT NULL
                    AND ex_map_nested.exception_message IS NULL
                    THEN 'EXCEPTION_PARSING_FAILED'
                WHEN
                    flattened.plugin_category = ex_map_nested.plugin_category
                    THEN 'FAILED'
                WHEN
                    flattened.plugin_category != ex_map_nested.plugin_category
                    THEN 'INCOMPLETE_EL_PAIR'
                WHEN
                    incomplete_plugins.exception_dict IS NULL
                    THEN 'NULL_EXCEPTION'
                ELSE 'OTHER_FAILURE'
            END
        WHEN flattened.cli_command = 'run' THEN
            CASE
                -- It had a completed event so it succeeded
                WHEN incomplete_plugins.execution_id IS NULL THEN 'SUCCESS'
                -- It never completed but also didnt have a failure,
                -- aborted or skipped.
                WHEN
                    NOT ARRAY_CONTAINS(
                        'failed'::VARIANT, flattened.event_statuses
                    ) THEN 'ABORTED-SKIPPED'
                -- We couldnt parse the exception to know which plugin
                -- in the EL block failed
                WHEN
                    flattened.block_type = 'ExtractLoadBlocks'
                    AND incomplete_plugins.hashed_runtime_error IS NOT NULL
                    AND ex_map_top.exception_message IS NULL
                    THEN 'EXCEPTION_PARSING_FAILED'
                -- EL Block, no exception to parse. Failed but status unknown.
                WHEN
                    flattened.block_type = 'ExtractLoadBlocks'
                    AND incomplete_plugins.exception_dict IS NULL
                    THEN 'NULL_EXCEPTION'
                -- EL block and parsed/unhashed exception matches this
                -- plugin category. It caused the failure
                WHEN
                    flattened.block_type = 'ExtractLoadBlocks'
                    AND flattened.plugin_category = ex_map_top.plugin_category
                    THEN 'FAILED'
                -- EL block and parsed/unhashed exception doesnt match 
                -- plugin category, didnt fail but it also isnt successful
                WHEN
                    flattened.block_type = 'ExtractLoadBlocks'
                    AND flattened.plugin_category != ex_map_top.plugin_category
                    THEN 'INCOMPLETE_EL_PAIR'
                -- Invoker has only 1 plugin involved,
                -- failed no matter what the exception was
                WHEN flattened.block_type = 'InvokerCommand' THEN 'FAILED'
                ELSE 'OTHER_FAILURE'
            END
        WHEN flattened.cli_command = 'invoke' THEN
            CASE
                -- It had a completed event so it succeeded
                WHEN incomplete_plugins.execution_id IS NULL THEN 'SUCCESS'
                -- It never completed but also didnt have a failure
                -- aborted or skipped.
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
LEFT JOIN {{ ref('runtime_exceptions') }} AS ex_map_top
    ON incomplete_plugins.top_runtime_error = ex_map_top.exception_message
LEFT JOIN {{ ref('runtime_exceptions') }} AS ex_map_nested
    ON incomplete_plugins.nested_runtime_error = ex_map_nested.exception_message
WHERE flattened.cli_command IN ('elt', 'run', 'invoke')
