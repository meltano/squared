WITH plugin_prep AS (
    SELECT
        plugin_executions.execution_id,
        cli_executions_base.project_id,
        cli_executions_base.environment_name_hash AS env_id,
        ARRAY_AGG(
            COALESCE(
                plugin_executions.plugin_surrogate_key,
                plugin_executions.plugin_name
            )
        ) AS plugins
    FROM {{ ref('plugin_executions') }}
    LEFT JOIN {{ ref('cli_executions_base') }}
        ON plugin_executions.execution_id = cli_executions_base.execution_id
    WHERE cli_executions_base.cli_command IN ('elt', 'run')
    GROUP BY 1, 2, 3
)

SELECT
    *,
    {{ dbt_utils.surrogate_key(
        [
            'plugins',
            'env_id',
            'project_id'
        ]
    ) }} AS pipeline_pk
FROM plugin_prep
