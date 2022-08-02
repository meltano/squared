{{
    config(materialized='table')
}}

SELECT
    {{ dbt_utils.surrogate_key(
        [
            'structured_executions.project_id',
            'cmd_parsed_all.environment'
        ]
    ) }} AS environment_fk,
    structured_executions.execution_id
FROM {{ ref('structured_executions') }}
LEFT JOIN
    {{ ref('cmd_parsed_all') }} ON
        structured_executions.command = cmd_parsed_all.command

UNION ALL

SELECT
    {{ dbt_utils.surrogate_key(
        [
            'unstructured_executions.project_id',
            'unstructured_executions.environment_name_hash'
        ]
    ) }} AS environment_fk,
    unstructured_executions.execution_id
FROM {{ ref('unstructured_executions') }}
