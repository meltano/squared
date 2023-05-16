WITH active_projects AS (

    SELECT
        project_id,
        MIN(date_day) AS first_active_date,
        MAX(date_day) AS last_active_date
    FROM {{ ref('daily_active_projects') }}
    GROUP BY 1

)

SELECT
    project_base.project_id,
    project_base.first_event_at AS project_first_event_at,
    project_base.last_event_at AS project_last_event_at,
    project_base.project_id_source,
    active_projects.first_active_date AS project_first_active_date,
    active_projects.last_active_date AS project_last_active_date,
    project_base.lifespan_days AS project_lifespan_days,
    project_base.lifespan_hours AS project_lifespan_hours,
    project_base.lifespan_mins AS project_lifespan_mins,
    project_base.is_ci_only,
    project_base.opted_out_at,
    project_base.first_meltano_version,
    project_base.last_meltano_version,
    project_base.init_project_directory,
    project_base.has_opted_out,
    project_base.project_org_name,
    project_base.project_org_domain,
    COALESCE(project_base.event_total, 0) AS event_total,
    COALESCE(project_base.exec_event_total, 0) AS exec_event_total,
    COALESCE(
        project_base.exec_event_success_total, 0
    ) AS exec_event_success_total,
    COALESCE(project_base.unique_pipelines_count, 0) AS unique_pipelines_count,
    COALESCE(
        project_base.pipeline_runs_count_all, 0
    ) AS pipeline_runs_count_all,
    COALESCE(
        project_base.pipeline_runs_count_success, 0
    ) AS pipeline_runs_count_success,
    COALESCE(
        project_base.unique_ip_address_count, 0
    ) AS unique_ip_address_count,
    COALESCE(project_base.add_count_all, 0) AS add_count_all,
    COALESCE(project_base.add_count_success, 0) AS add_count_success,
    COALESCE(project_base.config_count_all, 0) AS config_count_all,
    COALESCE(project_base.config_count_success, 0) AS config_count_success,
    COALESCE(project_base.discover_count_all, 0) AS discover_count_all,
    COALESCE(project_base.discover_count_success, 0) AS discover_count_success,
    COALESCE(project_base.elt_count_all, 0) AS elt_count_all,
    COALESCE(project_base.elt_count_success, 0) AS elt_count_success,
    COALESCE(project_base.environment_count_all, 0) AS environment_count_all,
    COALESCE(
        project_base.environment_count_success, 0
    ) AS environment_count_success,
    COALESCE(project_base.init_count_all, 0) AS init_count_all,
    COALESCE(project_base.init_count_success, 0) AS init_count_success,
    COALESCE(project_base.install_count_all, 0) AS install_count_all,
    COALESCE(project_base.install_count_success, 0) AS install_count_success,
    COALESCE(project_base.invoke_count_all, 0) AS invoke_count_all,
    COALESCE(project_base.invoke_count_success, 0) AS invoke_count_success,
    COALESCE(project_base.lock_count_all, 0) AS lock_count_all,
    COALESCE(project_base.lock_count_success, 0) AS lock_count_success,
    COALESCE(project_base.remove_count_all, 0) AS remove_count_all,
    COALESCE(project_base.remove_count_success, 0) AS remove_count_success,
    COALESCE(project_base.run_count_all, 0) AS run_count_all,
    COALESCE(project_base.run_count_success, 0) AS run_count_success,
    COALESCE(project_base.job_count_all, 0) AS job_count_all,
    COALESCE(project_base.job_count_success, 0) AS job_count_success,
    COALESCE(project_base.schedule_count_all, 0) AS schedule_count_all,
    COALESCE(project_base.schedule_count_success, 0) AS schedule_count_success,
    COALESCE(project_base.select_count_all, 0) AS select_count_all,
    COALESCE(project_base.select_count_success, 0) AS select_count_success,
    COALESCE(project_base.state_count_all, 0) AS state_count_all,
    COALESCE(project_base.state_count_success, 0) AS state_count_success,
    COALESCE(project_base.test_count_all, 0) AS test_count_all,
    COALESCE(project_base.test_count_success, 0) AS test_count_success,
    COALESCE(project_base.ui_count_all, 0) AS ui_count_all,
    COALESCE(project_base.ui_count_success, 0) AS ui_count_success,
    COALESCE(project_base.user_count_all, 0) AS user_count_all,
    COALESCE(project_base.user_count_success, 0) AS user_count_success,
    COALESCE(project_base.upgrade_count_all, 0) AS upgrade_count_all,
    COALESCE(project_base.upgrade_count_success, 0) AS upgrade_count_success,
    COALESCE(project_base.version_count_all, 0) AS version_count_all,
    COALESCE(project_base.version_count_success, 0) AS version_count_success,
    COALESCE(project_base.plugin_name_count_all, 0) AS plugin_name_count_all,
    COALESCE(
        project_base.plugin_parent_name_count_all, 0
    ) AS plugin_parent_name_count_all,
    COALESCE(
        project_base.plugin_pip_url_count_all, 0
    ) AS plugin_pip_url_count_all,
    COALESCE(
        project_base.plugin_name_count_success, 0
    ) AS plugin_name_count_success,
    COALESCE(
        project_base.plugin_parent_name_count_success, 0
    ) AS plugin_parent_name_count_success,
    COALESCE(
        project_base.plugin_pip_url_count_success, 0
    ) AS plugin_pip_url_count_success,
    COALESCE(
        project_base.el_plugin_name_count_all, 0
    ) AS el_plugin_name_count_all,
    COALESCE(
        project_base.el_plugin_parent_name_count_all, 0
    ) AS el_plugin_parent_name_count_all,
    COALESCE(
        project_base.el_plugin_pip_url_count_all, 0
    ) AS el_plugin_pip_url_count_all,
    COALESCE(
        project_base.el_plugin_name_count_success, 0
    ) AS el_plugin_name_count_success,
    COALESCE(
        project_base.el_plugin_parent_name_count_success, 0
    ) AS el_plugin_parent_name_count_success,
    COALESCE(
        project_base.el_plugin_pip_url_count_success, 0
    ) AS el_plugin_pip_url_count_success,
    COALESCE(project_base.non_gsg_add, 0) AS non_gsg_add,
    COALESCE(project_base.non_gsg_add_success, 0) AS non_gsg_add_success,
    COALESCE(project_base.non_gsg_exec, 0) AS non_gsg_exec,
    COALESCE(project_base.non_gsg_exec_success, 0) AS non_gsg_exec_success,
    COALESCE(project_base.non_gsg_pipeline, 0) AS non_gsg_pipeline,
    COALESCE(
        project_base.non_gsg_pipeline_success, 0
    ) AS non_gsg_pipeline_success,
    COALESCE(
        active_projects.last_active_date = CURRENT_DATE(),
        FALSE
    ) AS is_currently_active,
    COALESCE(
        project_base.project_id_source = 'random'
        OR project_base.is_ci_only = TRUE
        OR project_base.lifespan_mins <= 5
        OR project_base.is_state_in_first_exec = TRUE
        OR (
            ARRAY_SIZE(project_base.ip_hash_list) = 1
            -- Ephemeral IP exclude list
            AND project_base.ip_hash_list[0] IN (
                'e6e4b47d8cd8840dd90ea08f5e54033f'
            )
        ),
        FALSE
    ) AS is_ephemeral_project_id,
    COALESCE(
        project_base.init_project_directory IN (
            -- codespace original path - 'PosixPath(\'new_project\')'
            'e5ca2eeb4da09ea1a66c3d9391b5bf43296e309c619c04914ac5bffbb3e7cf54',
            -- updated uuid - 'PosixPath(\'b54c6cfe2f8f831389a5b9ca409f410c\')'
            '781d839e18d017b347cf90a22e18b407e3cdacb2a9cc907d3693893a790fdc4c'
        ),
        FALSE
    ) AS is_codespace_demo,
    COALESCE(
        project_base.init_project_directory IN (
            -- full GSG tutorial path - 'PosixPath(\'my-meltano-project\')'
            'edd9334eaeaa3b81f964e18c5840955de8791ea220740459f7393deca03085f6',
            -- mulit part GSG tutorial path - 'PosixPath(\'my-new-project\')'
            'ffd7f2044d5bf2efc6bd4353979041951c565125c08186e3160be926a6ee1e75'
        ),
        FALSE
    ) AS is_gsg_tutorial
FROM {{ ref('project_base') }}
LEFT JOIN
    active_projects ON
    project_base.project_id = active_projects.project_id
