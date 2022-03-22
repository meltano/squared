SELECT
    project_id,
    MIN(event_date) AS first_event_date,
    MAX(event_date) AS last_event_date,
    DATEDIFF('day', MIN(event_date), MAX(event_date)) AS lifespan_days,
    SUM(event_count) AS events_total,
    COUNT(DISTINCT command) AS unique_commands,
    COUNT(DISTINCT command_category) AS unique_command_categories,
    SUM(CASE WHEN is_plugin_dbt THEN event_count ELSE 0 END) AS dbt_event_total,
    SUM(
        CASE WHEN is_plugin_singer THEN event_count ELSE 0 END
    ) AS singer_event_total,
    SUM(
        CASE WHEN is_plugin_airflow THEN event_count ELSE 0 END
    ) AS airflow_event_total,
    SUM(
        CASE WHEN is_plugin_dagster THEN event_count ELSE 0 END
    ) AS dagster_event_total,
    SUM(
        CASE WHEN is_plugin_lightdash THEN event_count ELSE 0 END
    ) AS lightdash_event_total,
    SUM(
        CASE WHEN is_plugin_superset THEN event_count ELSE 0 END
    ) AS superset_event_total,
    SUM(
        CASE WHEN is_plugin_sqlfluff THEN event_count ELSE 0 END
    ) AS sqlfluff_event_total,
    SUM(
        CASE WHEN is_os_feature_environments THEN event_count ELSE 0 END
    ) AS environments_event_total,
    SUM(
        CASE WHEN is_os_feature_test THEN event_count ELSE 0 END
    ) AS test_event_total,
    SUM(
        CASE WHEN is_os_feature_run THEN event_count ELSE 0 END
    ) AS run_event_total,
    COALESCE(SUM(
        event_count
    ) = 1 AND MAX(command_category) = 'meltano init',
    FALSE) AS is_tracking_disabled,
    COALESCE(MAX(
        event_date
    ) < DATEADD(MONTH, -1, CURRENT_DATE),
    FALSE) AS is_churned,
    SUM(
        CASE
            WHEN
                command_category IN (
                    'meltano elt',
                    'meltano invoke',
                    'meltano run',
                    'meltano test',
                    'meltano ui'
                ) THEN event_count
            ELSE 0
        END
    ) AS exec_event_total
FROM {{ ref('fact_cli_events') }}
GROUP BY project_id
ORDER BY last_event_date DESC
