SELECT
    MAX(COALESCE(cli_started_ts, cli_finished_ts)) AS updated_date,
    'meltano_metrics' AS metric_type
FROM {{ ref('fact_plugin_usage') }}

UNION ALL

SELECT
    -- TODO: cast to timestamp in stage model
    MAX(batch_ts) AS updated_date,
    'github_metrics' AS metric_type
FROM {{ ref('singer_repo_dim') }}
