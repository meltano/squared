SELECT
    MAX(event_date) AS updated_date,
    'meltano_metrics' AS metric_type
FROM {{ ref('cli_plugin_usage') }}

UNION ALL

SELECT
    -- TODO: cast to timestamp in stage model
    MAX(DATE_PARSE(batch_ts, '%Y-%m-%d %H:%i:%s.%f')) AS updated_date,
    'github_metrics' AS metric_type
FROM {{ ref('fact_repo_metrics') }}
