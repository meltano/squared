WITH base AS (
    SELECT
        unstructured_executions.*,
        plugin.value AS plugin_details,
        {{ dbt_utils.surrogate_key(
            ['plugin.value']
        ) }} AS plugin_surrogate_key
    FROM {{ ref('unstructured_executions') }},
        LATERAL FLATTEN(input => plugins) AS plugin_list, -- noqa: L025, L031
        LATERAL FLATTEN(
            input => plugin_list.value::VARIANT
        ) AS plugin -- noqa: L031
)


SELECT
    plugin_executions_block.plugin_exec_block_pk AS unstruct_plugin_exec_pk,
    plugin_executions_block.plugin_surrogate_key,
    plugin_executions_block.execution_id,
    'snowplow' AS event_source,
    plugin_executions_block.plugin_started,
    plugin_executions_block.plugin_ended,
    plugin_executions_block.plugin_runtime_ms,
    plugin_executions_block.block_type,
    plugin_executions_block.completion_status
FROM {{ ref('plugin_executions_block') }}
LEFT JOIN {{ ref('unstruct_plugins') }}
    ON
        unstruct_plugins.plugin_surrogate_key
        = plugin_executions_block.plugin_surrogate_key

UNION ALL

SELECT DISTINCT
    {{ dbt_utils.surrogate_key(
        [
            'base.plugin_surrogate_key',
            'base.execution_id'
        ]
    ) }} AS unstruct_plugin_exec_pk,
    base.plugin_surrogate_key,
    base.execution_id,
    base.event_source,
    NULL AS plugin_started,
    NULL AS plugin_ended,
    NULL AS plugin_runtime_ms,
    NULL AS block_type,
    CASE
        WHEN base.exit_code = '0' THEN 'SUCCESS_BLOCK_CLI_LEVEL'
        -- We can't parse out what plugin failed in ELT without more information
        WHEN base.cli_command = 'elt' THEN 'UNKNOWN_FAILED_OR_ABORTED'
        ELSE 'FAILED_BLOCK_CLI_LEVEL'
    END AS completion_status
FROM base
LEFT JOIN {{ ref('plugin_executions_block') }}
    ON {{ dbt_utils.surrogate_key(
        [
            'plugin_executions_block.plugin_surrogate_key',
            'plugin_executions_block.execution_id'
        ]
    ) }} = {{ dbt_utils.surrogate_key(
        [
            'base.plugin_surrogate_key',
            'base.execution_id'
        ]
    ) }}
WHERE plugin_executions_block.execution_id IS NULL
