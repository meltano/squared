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
        ) WITHIN GROUP (
            ORDER BY
                plugin_executions.plugin_started, COALESCE(
                    plugin_executions.plugin_surrogate_key,
                    plugin_executions.plugin_name
                ) DESC
        ) AS plugins,
        MAX(plugin_executions.is_test_plugin) AS is_test_pipeline
    FROM {{ ref('plugin_executions') }}
    LEFT JOIN {{ ref('cli_executions_base') }}
        ON plugin_executions.execution_id = cli_executions_base.execution_id
    WHERE cli_executions_base.cli_command IN ('elt', 'run')
    GROUP BY 1, 2, 3
)

SELECT
    plugin_prep.*,
    cli_executions_base.cli_runtime_ms AS pipeline_runtime_ms,
    CASE
        WHEN cli_executions_base.cli_runtime_ms IS NULL THEN 'N/A'
        WHEN cli_executions_base.cli_runtime_ms <= 5000 THEN '< 5s'
        WHEN
            cli_executions_base.cli_runtime_ms
            BETWEEN 5001 AND 10001 THEN '5s - 10s'
        WHEN
            cli_executions_base.cli_runtime_ms
            BETWEEN 10001 AND 30000 THEN '10s - 30s'
        WHEN
            cli_executions_base.cli_runtime_ms
            BETWEEN 30001 AND 60000 THEN '30s - 1m'
        WHEN
            cli_executions_base.cli_runtime_ms
            BETWEEN 60001 AND 180000 THEN '1m - 3m'
        WHEN
            cli_executions_base.cli_runtime_ms
            BETWEEN 180001 AND 300000 THEN '3m - 5m'
        WHEN
            cli_executions_base.cli_runtime_ms
            BETWEEN 300001 AND 600000 THEN '5m - 10m'
        WHEN
            cli_executions_base.cli_runtime_ms
            BETWEEN 600001 AND 1800000 THEN '10m - 30m'
        WHEN
            cli_executions_base.cli_runtime_ms
            BETWEEN 1800001 AND 3600000 THEN '30m - 1hr'
        WHEN
            cli_executions_base.cli_runtime_ms
            BETWEEN 3600001 AND 10800000 THEN '1hr - 3hr'
        WHEN cli_executions_base.cli_runtime_ms >= 10800001 THEN '3hr+'
        ELSE 'Failed to bucket'
    END AS pipeline_runtime_bin,
    {{ dbt_utils.surrogate_key(
        [
            'plugin_prep.plugins',
            'plugin_prep.env_id',
            'plugin_prep.project_id'
        ]
    ) }} AS pipeline_pk
FROM plugin_prep
LEFT JOIN {{ ref('cli_executions_base') }}
    ON plugin_prep.execution_id = cli_executions_base.execution_id
