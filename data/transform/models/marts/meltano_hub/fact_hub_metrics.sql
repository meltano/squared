WITH plugin_use_3m AS (

    SELECT
      plugin_name,
      SUM(event_count) AS execution_count,
      COUNT(DISTINCT project_id) AS project_count
    FROM {{ ref('cli_plugin_usage') }}
    WHERE plugin_type IN ('tap', 'target')
      AND event_date >= CURRENT_DATE - INTERVAL '3' MONTH
    GROUP BY 1

)
SELECT
  fact_repo_metrics.repo_full_name,
  fact_repo_metrics.created_at_timestamp,
  fact_repo_metrics.last_push_timestamp,
  fact_repo_metrics.last_updated_timestamp,
  -- TODO: cast these in the staging table
  CAST(fact_repo_metrics.num_forks AS INT) AS num_forks,
  CAST(fact_repo_metrics.num_open_issues AS INT) AS num_open_issues,
  CAST(fact_repo_metrics.num_stargazers AS INT) AS num_stargazers,
  CAST(fact_repo_metrics.num_watchers AS INT) AS num_watchers,
  COALESCE(plugin_use_3m.execution_count, 0) AS meltano_executions_3m,
  COALESCE(plugin_use_3m.project_count, 0) AS meltano_projects_count_3m
FROM {{ source('hub_meltano', 'fact_repo_metrics') }}
LEFT JOIN plugin_use_3m
  ON fact_repo_metrics.connector_name = plugin_use_3m.plugin_name

