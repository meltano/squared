WITH plugin_prep AS (
    SELECT
        execution_id,
        project_id,
        env_id,
        ARRAY_AGG(
            COALESCE(
                plugin_surrogate_key,
                plugin_name
            )
        ) AS plugins
    FROM {{ ref('plugin_executions') }}
    WHERE cli_command IN ('elt', 'run')
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
