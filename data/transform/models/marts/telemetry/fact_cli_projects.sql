SELECT
    project_id,
    MIN(event_date) AS first_event_date,
    MAX(event_date) AS last_event_date,
    DATE_DIFF('day', MIN(event_date), MAX(event_date)) AS lifespan_days,
    SUM(event_count) AS events_total,
    COUNT(DISTINCT command) AS unique_commands,
    COUNT(DISTINCT command_category) AS unique_command_categories,
    SUM(CASE WHEN is_plugin_dbt THEN 1 ELSE 0 END) AS dbt_event_total,
    SUM(CASE WHEN is_plugin_singer THEN 1 ELSE 0 END) AS singer_event_total,
    SUM(CASE WHEN is_plugin_airflow THEN 1 ELSE 0 END) AS airflow_event_total,
    SUM(CASE WHEN is_plugin_dagster THEN 1 ELSE 0 END) AS dagster_event_total,
    SUM(
        CASE WHEN is_plugin_lightdash THEN 1 ELSE 0 END
    ) AS lightdash_event_total,
    SUM(CASE WHEN is_plugin_superset THEN 1 ELSE 0 END) AS superset_event_total,
    SUM(CASE WHEN is_plugin_sqlfluff THEN 1 ELSE 0 END) AS sqlfluff_event_total,
    SUM(
        CASE WHEN is_os_feature_environments THEN 1 ELSE 0 END
    ) AS environments_event_total,
    SUM(CASE WHEN is_os_feature_test THEN 1 ELSE 0 END) AS test_event_total,
    SUM(CASE WHEN is_os_feature_run THEN 1 ELSE 0 END) AS run_event_total,
    COALESCE(SUM(
        event_count
    ) = 1 AND MAX(command_category) = 'meltano init',
    FALSE) AS is_tracking_disabled,
    COALESCE(MAX(
        event_date
    ) < CURRENT_DATE - INTERVAL '28' day,
    FALSE) AS is_churned
FROM {{ ref('fact_cli_events') }}
GROUP BY project_id
ORDER BY last_event_date DESC
