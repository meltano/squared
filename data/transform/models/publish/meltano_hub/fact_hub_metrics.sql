WITH plugin_use_3m AS (

    SELECT
        COALESCE(NULLIF(parent_name, 'UNKNOWN'), plugin_name) AS plugin_name,
        SUM(event_count) AS execution_count,
        COUNT(DISTINCT project_id) AS project_count
    FROM {{ ref('fact_plugin_usage') }}
    WHERE
        plugin_category = 'singer'
        AND COALESCE(
            cli_started_ts, cli_finished_ts
        ) >= DATEADD(MONTH, -3, CURRENT_DATE)
    GROUP BY 1

),

rename_join AS (

    SELECT
        fact_repo_metrics.repo_full_name,
        fact_repo_metrics.created_at_ts AS created_at_timestamp,
        fact_repo_metrics.last_push_ts AS last_push_timestamp,
        fact_repo_metrics.last_updated_ts AS last_updated_timestamp,
        -- TODO: cast these in the staging table
        CAST(fact_repo_metrics.num_forks AS INT) AS num_forks,
        CAST(fact_repo_metrics.num_open_issues AS INT) AS num_open_issues,
        CAST(fact_repo_metrics.num_stargazers AS INT) AS num_stargazers,
        CAST(fact_repo_metrics.num_watchers AS INT) AS num_watchers,
        COALESCE(plugin_use_3m.execution_count, 0) AS meltano_exec_count_3m,
        COALESCE(plugin_use_3m.project_count, 0) AS meltano_project_id_count_3m
    FROM {{ ref('fact_repo_metrics') }}
    LEFT JOIN plugin_use_3m
        ON
            REPLACE(
                fact_repo_metrics.repo_name,
                'pipelinewise-',
                ''
            ) = plugin_use_3m.plugin_name

)

SELECT *
FROM rename_join
