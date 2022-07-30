WITH base AS (

    SELECT
        unstruct_plugin_executions.unstruct_plugin_exec_pk AS plugin_exec_pk,
        unstruct_plugin_executions.execution_id,
        unstruct_plugin_executions.plugin_started,
        unstruct_plugin_executions.plugin_ended,
        unstruct_plugin_executions.plugin_runtime_ms,
        unstruct_plugin_executions.completion_status,
        unstruct_plugin_executions.event_source,
        1 AS event_count,
        'unstructured' AS event_type,
        unstruct_plugins.plugin_name,
        unstruct_plugins.parent_name,
        unstruct_plugins.executable,
        unstruct_plugins.namespace,
        unstruct_plugins.pip_url,
        unstruct_plugins.variant_name AS plugin_variant,
        unstruct_plugins.command AS plugin_command,
        unstruct_plugins.plugin_type,
        unstruct_plugins.plugin_category,
        unstruct_plugins.plugin_surrogate_key
    FROM {{ ref('unstruct_plugin_executions') }}
    LEFT JOIN {{ ref('unstruct_plugins') }}
        ON unstruct_plugin_executions.plugin_surrogate_key = unstruct_plugins.plugin_surrogate_key

    UNION ALL

    SELECT
        struct_plugin_executions.struct_plugin_exec_pk AS plugin_exec_pk,
        struct_plugin_executions.execution_id,
        NULL AS plugin_started,
        NULL AS plugin_ended,
        NULL AS plugin_runtime_ms,
        'SUCCESS_STRUCT' AS completion_status,
        struct_plugin_executions.event_source,
        struct_plugin_executions.event_count,
        'structured' AS event_type,
        struct_plugin_executions.plugin_name,
        struct_plugin_executions.parent_name,
        struct_plugin_executions.executable,
        struct_plugin_executions.namespace,
        struct_plugin_executions.pip_url,
        struct_plugin_executions.plugin_variant,
        struct_plugin_executions.plugin_command,
        struct_plugin_executions.plugin_type,
        struct_plugin_executions.plugin_category,
        NULL AS plugin_surrogate_key
    FROM {{ ref('struct_plugin_executions') }}

)

SELECT
    plugin_exec_pk,
    execution_id,
    plugin_started,
    plugin_ended,
    plugin_runtime_ms,
    event_source,
    event_count,
    event_type,
    plugin_name,
    parent_name,
    executable,
    namespace,
    pip_url,
    plugin_variant,
    plugin_command,
    plugin_type,
    plugin_category,
    plugin_surrogate_key,
    completion_status AS completion_sub_status,
    CASE
        WHEN completion_status IN ('SUCCESS', 'SUCCESS_STRUCT', 'SUCCESS_BLOCK_CLI_LEVEL') THEN 'SUCCESS'
        WHEN completion_status IN ('FAILED') THEN 'FAILED'
        WHEN completion_status IN ('ABORTED-SKIPPED', 'INCOMPLETE_EL_PAIR') THEN 'ABORTED'
        WHEN completion_status IN ('NULL_EXCEPTION', 'EXCEPTION_PARSING_FAILED', 'OTHER_FAILURE', 'FAILED_BLOCK_CLI_LEVEL') THEN 'UNKNOWN_FAILED_OR_ABORTED'
        ELSE 'OTHER'
    END AS completion_status
FROM base
