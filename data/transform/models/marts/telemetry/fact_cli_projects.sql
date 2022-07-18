WITH base AS (
    SELECT
        project_id,
        DATEDIFF('day', MIN(event_date), MAX(event_date)) AS lifespan_days,
        SUM(event_count) AS events_total,
        COUNT(DISTINCT command) AS unique_commands,
        COUNT(DISTINCT command_category) AS unique_command_categories,
        SUM(
            CASE WHEN is_plugin_dbt THEN event_count ELSE 0 END
        ) AS dbt_event_total,
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
            CASE WHEN is_os_feature_mappers THEN event_count ELSE 0 END
        ) AS mappers_event_total,
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
        FALSE) AS is_churned
    FROM {{ ref('cli_executions_base') }}
    GROUP BY project_id
)
SELECT
    base.*,
    project_dim.first_event_at AS first_event_date,
    project_dim.last_event_at AS last_event_date,
    project_dim.is_active,
    project_dim.exec_event_total,
    project_dim.project_id_source
FROM base
LEFT JOIN {{ ref('project_dim') }}
    ON base.project_id = project_dim.project_id
