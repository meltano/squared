WITH first_values AS (

    SELECT DISTINCT
        project_id,
        FIRST_VALUE(
            CASE
                WHEN cli_command != 'init'
                    THEN project_uuid_source
            END
        ) IGNORE NULLS OVER (
            PARTITION BY project_id ORDER BY event_created_at ASC
        ) AS first_source,
        FIRST_VALUE(
            meltano_version
        ) OVER (
            PARTITION BY
                project_id
            ORDER BY COALESCE(started_ts, finished_ts) ASC
        ) AS first_meltano_version,
        LAST_VALUE(
            meltano_version
        ) OVER (
            PARTITION BY
                project_id
            ORDER BY COALESCE(started_ts, finished_ts) ASC
        ) AS last_meltano_version,
        FIRST_VALUE(
            GET(options_obj, 0):init:project_directory
        ) IGNORE NULLS OVER (
            PARTITION BY
                project_id
            ORDER BY COALESCE(started_ts, finished_ts) ASC
        ) AS first_project_directory
    FROM {{ ref('cli_executions_base') }}

),

plugin_aggregates AS (

    SELECT
        cli_executions_base.project_id,
        COUNT(DISTINCT plugin_executions.plugin_name) AS plugin_name_count_all,
        COUNT(
            DISTINCT plugin_executions.parent_name
        ) AS plugin_parent_name_count_all,
        COUNT(DISTINCT plugin_executions.pip_url) AS plugin_pip_url_count_all,
        COUNT(
            DISTINCT CASE
                WHEN
                    COALESCE(
                        cli_executions_base.exit_code, 1
                    ) = 0 THEN plugin_executions.plugin_name
            END
        ) AS plugin_name_count_success,
        COUNT(
            DISTINCT CASE
                WHEN
                    COALESCE(
                        cli_executions_base.exit_code, 1
                    ) = 0 THEN plugin_executions.parent_name
            END
        ) AS plugin_parent_name_count_success,
        COUNT(
            DISTINCT CASE
                WHEN
                    COALESCE(
                        cli_executions_base.exit_code, 1
                    ) = 0 THEN plugin_executions.pip_url
            END
        ) AS plugin_pip_url_count_success,
        COUNT(
            DISTINCT CASE
                WHEN
                    plugin_executions.plugin_type IN (
                        'extractors', 'loaders'
                    ) THEN plugin_executions.plugin_name
            END
        ) AS el_plugin_name_count_all,
        COUNT(
            DISTINCT CASE
                WHEN
                    plugin_executions.plugin_type IN (
                        'extractors', 'loaders'
                    ) THEN plugin_executions.parent_name
            END
        ) AS el_plugin_parent_name_count_all,
        COUNT(
            DISTINCT CASE
                WHEN
                    plugin_executions.plugin_type IN (
                        'extractors', 'loaders'
                    ) THEN plugin_executions.pip_url
            END
        ) AS el_plugin_pip_url_count_all,
        COUNT(
            DISTINCT CASE
                WHEN
                    plugin_executions.plugin_type IN (
                        'extractors', 'loaders'
                    ) AND COALESCE(
                        cli_executions_base.exit_code, 1
                    ) = 0 THEN plugin_executions.plugin_name
            END
        ) AS el_plugin_name_count_success,
        COUNT(
            DISTINCT CASE
                WHEN
                    plugin_executions.plugin_type IN (
                        'extractors', 'loaders'
                    ) AND COALESCE(
                        cli_executions_base.exit_code, 1
                    ) = 0 THEN plugin_executions.parent_name
            END
        ) AS el_plugin_parent_name_count_success,
        COUNT(
            DISTINCT CASE
                WHEN
                    plugin_executions.plugin_type IN (
                        'extractors', 'loaders'
                    ) AND COALESCE(
                        cli_executions_base.exit_code, 1
                    ) = 0 THEN plugin_executions.pip_url
            END
        ) AS el_plugin_pip_url_count_success,
        COUNT(
            DISTINCT CASE
                WHEN cli_executions_base.cli_command IN ('add', 'install')
                    AND plugin_executions.plugin_name NOT IN (
                        'tap-gitlab',
                        'tap-github',
                        'target-jsonl',
                        'target-postgres'
                    )
                    AND plugin_executions.plugin_type IN (
                        'extractors', 'loaders'
                    )
                    THEN plugin_executions.plugin_name
            END
        ) AS non_gsg_add,
        COUNT(
            DISTINCT CASE
                WHEN cli_executions_base.cli_command IN ('add', 'install')
                    AND plugin_executions.plugin_name NOT IN (
                        'tap-gitlab',
                        'tap-github',
                        'target-jsonl',
                        'target-postgres'
                    )
                    AND plugin_executions.plugin_type IN (
                        'extractors', 'loaders'
                    )
                    AND plugin_executions.completion_status = 'SUCCESS'
                    THEN plugin_executions.plugin_name
            END
        ) AS non_gsg_add_success,
        COUNT(
            DISTINCT CASE
                WHEN cli_executions_base.is_exec_event
                    AND plugin_executions.plugin_name NOT IN (
                        'tap-gitlab',
                        'tap-github',
                        'target-jsonl',
                        'target-postgres'
                    )
                    AND plugin_executions.plugin_type IN (
                        'extractors', 'loaders'
                    )
                    THEN plugin_executions.plugin_name
            END
        ) AS non_gsg_exec,
        COUNT(
            DISTINCT CASE
                WHEN cli_executions_base.is_exec_event
                    AND plugin_executions.plugin_name NOT IN (
                        'tap-gitlab',
                        'tap-github',
                        'target-jsonl',
                        'target-postgres'
                    )
                    AND plugin_executions.plugin_type IN (
                        'extractors', 'loaders'
                    )
                    AND plugin_executions.completion_status = 'SUCCESS'
                    THEN plugin_executions.plugin_name
            END
        ) AS non_gsg_exec_success,
        COUNT(
            DISTINCT CASE
                WHEN pipeline_executions.pipeline_pk IS NOT NULL
                    AND plugin_executions.plugin_name NOT IN (
                        'tap-gitlab',
                        'tap-github',
                        'target-jsonl',
                        'target-postgres'
                    )
                    AND plugin_executions.plugin_type IN (
                        'extractors', 'loaders'
                    )
                    THEN plugin_executions.plugin_name
            END
        ) AS non_gsg_pipeline,
        COUNT(
            DISTINCT CASE
                WHEN pipeline_executions.pipeline_pk IS NOT NULL
                    AND plugin_executions.plugin_name NOT IN (
                        'tap-gitlab',
                        'tap-github',
                        'target-jsonl',
                        'target-postgres'
                    )
                    AND plugin_executions.plugin_type IN (
                        'extractors', 'loaders'
                    )
                    AND plugin_executions.completion_status = 'SUCCESS'
                    THEN plugin_executions.plugin_name
            END
        ) AS non_gsg_pipeline_success
    FROM {{ ref('plugin_executions') }}
    LEFT JOIN {{ ref('cli_executions_base') }}
        ON plugin_executions.execution_id = cli_executions_base.execution_id
    LEFT JOIN {{ ref('pipeline_executions') }}
        ON cli_executions_base.execution_id = pipeline_executions.execution_id
    GROUP BY 1

),

project_aggregates AS (
    SELECT
        cli_executions_base.project_id,
        MIN(cli_executions_base.event_created_at) AS first_event_at,
        MAX(cli_executions_base.event_created_at) AS last_event_at,
        DATEDIFF(
            'day',
            MIN(cli_executions_base.event_created_at),
            MAX(cli_executions_base.event_created_at)
        ) AS lifespan_days,
        DATEDIFF(
            'hour',
            MIN(cli_executions_base.event_created_at),
            MAX(cli_executions_base.event_created_at)
        ) AS lifespan_hours,
        DATEDIFF(
            'minute',
            MIN(cli_executions_base.event_created_at),
            MAX(cli_executions_base.event_created_at)
        ) AS lifespan_mins,
        SUM(cli_executions_base.event_count) AS event_total,
        SUM(
            CASE
                WHEN
                    cli_executions_base.is_exec_event
                    THEN cli_executions_base.event_count
                ELSE 0
            END
        ) AS exec_event_total,
        SUM(
            CASE
                WHEN
                    cli_executions_base.is_exec_event
                    AND COALESCE(cli_executions_base.exit_code, 1) = 0
                    THEN cli_executions_base.event_count
                ELSE 0
            END
        ) AS exec_event_success_total,
        -- If we see null or non CI environment then FALSE
        COALESCE(
            MIN(COALESCE(cli_executions_base.is_ci_environment, FALSE)),
            FALSE
        ) AS is_ci_only,
        COUNT(DISTINCT pipeline_dim.pipeline_pk) AS unique_pipelines_count,
        SUM(
            CASE
                WHEN
                    pipeline_dim.pipeline_pk IS NOT NULL
                    THEN cli_executions_base.event_count
            END
        ) AS pipeline_runs_count_all,
        SUM(
            CASE
                WHEN
                    pipeline_dim.pipeline_pk IS NOT NULL AND COALESCE(
                        cli_executions_base.exit_code, 1
                    ) = 0 THEN cli_executions_base.event_count
            END
        ) AS pipeline_runs_count_success,
        {% for cli_command in [
            'add',
            'config',
            'discover',
            'elt',
            'environment',
            'init',
            'install',
            'invoke',
            'lock',
            'remove',
            'run',
            'job',
            'schedule',
            'select',
            'state',
            'test',
            'ui',
            'user',
            'upgrade',
            'version',
        ] %}
        SUM(
            CASE
                WHEN
                    cli_executions_base.cli_command = '{{ cli_command }}'
                    THEN cli_executions_base.event_count
            END
        ) AS {{ cli_command }}_count_all,
        SUM(
            CASE
                WHEN
                    cli_executions_base.cli_command = '{{ cli_command }}'
                    AND COALESCE(
                        cli_executions_base.exit_code, 1
                    ) = 0 THEN cli_executions_base.event_count
            END
        ) AS {{ cli_command }}_count_success
            {%- if not loop.last %},{% endif -%}
		{% endfor %}
    -- Active execution events
    -- Current segment
    FROM {{ ref('cli_executions_base') }}
    LEFT JOIN {{ ref('pipeline_executions') }}
        ON cli_executions_base.execution_id = pipeline_executions.execution_id
    LEFT JOIN {{ ref('pipeline_dim') }}
        ON pipeline_executions.pipeline_pk = pipeline_dim.pipeline_pk
    GROUP BY 1
)

SELECT
    project_aggregates.*,
    plugin_aggregates.plugin_name_count_all,
    plugin_aggregates.plugin_parent_name_count_all,
    plugin_aggregates.plugin_pip_url_count_all,
    plugin_aggregates.plugin_name_count_success,
    plugin_aggregates.plugin_parent_name_count_success,
    plugin_aggregates.plugin_pip_url_count_success,
    plugin_aggregates.el_plugin_name_count_all,
    plugin_aggregates.el_plugin_parent_name_count_all,
    plugin_aggregates.el_plugin_pip_url_count_all,
    plugin_aggregates.el_plugin_name_count_success,
    plugin_aggregates.el_plugin_parent_name_count_success,
    plugin_aggregates.el_plugin_pip_url_count_success,
    plugin_aggregates.non_gsg_add,
    plugin_aggregates.non_gsg_add_success,
    plugin_aggregates.non_gsg_exec,
    plugin_aggregates.non_gsg_exec_success,
    plugin_aggregates.non_gsg_pipeline,
    plugin_aggregates.non_gsg_pipeline_success,
    opt_outs.opted_out_at,
    COALESCE(
        first_values.first_source,
        -- TODO why would we ever get here?
        'UNKNOWN'
    ) AS project_id_source,
    COALESCE(
        first_values.first_meltano_version,
        'UNKNOWN'
    ) AS first_meltano_version,
    COALESCE(
        first_values.last_meltano_version,
        'UNKNOWN'
    ) AS last_meltano_version,
    COALESCE(
        first_values.first_project_directory,
        'UNKNOWN'
    ) AS init_project_directory,
    COALESCE(opt_outs.project_id IS NOT NULL, FALSE) AS has_opted_out,
    COALESCE(
        project_org_mapping.org_name,
        'UNKNOWN'
    ) AS project_org_name
FROM project_aggregates
LEFT JOIN
    first_values ON
        project_aggregates.project_id = first_values.project_id
LEFT JOIN {{ ref('opt_outs') }}
    ON project_aggregates.project_id = opt_outs.project_id
LEFT JOIN plugin_aggregates
    ON project_aggregates.project_id = plugin_aggregates.project_id
LEFT JOIN project_org_mapping
    ON project_aggregates.project_id = project_org_mapping.project_id
