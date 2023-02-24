WITH base AS (
    SELECT
        *,
        COUNT(*) OVER (PARTITION BY execution_id) AS plugin_count,
        ROW_NUMBER() OVER (
            PARTITION BY execution_id
            ORDER BY COALESCE(plugin_started, plugin_ended) DESC
        ) AS row_num,
        CASE
            WHEN MOD(row_num, 2) = 0 THEN row_num ELSE row_num + 1
        END AS plugin_pair_index
    FROM {{ ref('fact_plugin_usage') }}
    WHERE plugin_category = 'singer'
        AND plugin_type NOT IN ('mappers', 'transforms', 'UNKNOWN')
        AND cli_command IN ('elt', 'run')
        AND pipeline_fk IS NOT NULL
),

pair_roll_up AS (
    SELECT
        execution_id,
        plugin_pair_index,
        MAX(
            CASE WHEN plugin_type = 'extractors' THEN plugin_exec_pk END
        ) AS extractor_plugin_exec_pk,
        MAX(
            CASE WHEN plugin_type = 'loaders' THEN plugin_exec_pk END
        ) AS loader_plugin_exec_pk
    FROM base
    -- Run with null attributes isnt enough information to know order
    WHERE
        NOT(
            cli_command = 'run' AND meltano_version IS NULL AND plugin_count > 2
        )
        -- If one of the plugins is unknown type we want to exclude both.
        AND plugin_count > 1
    GROUP BY 1, 2
)

SELECT
    pair_roll_up.execution_id,
    extractor.event_count,
    extractor.plugin_exec_pk AS extractor_plugin_exec_pk,
    extractor.plugin_started AS extractor_plugin_started,
    extractor.plugin_ended AS extractor_plugin_ended,
    extractor.plugin_runtime_ms AS extractor_plugin_runtime_ms,
    extractor.completion_status AS extractor_completion_status,
    extractor.event_source AS extractor_event_source,
    extractor.event_type AS extractor_event_type,
    extractor.plugin_name AS extractor_plugin_name,
    extractor.parent_name AS extractor_parent_name,
    extractor.executable AS extractor_executable,
    extractor.namespace AS extractor_namespace,
    extractor.pip_url AS extractor_pip_url,
    extractor.plugin_variant AS extractor_plugin_variant,
    extractor.plugin_command AS extractor_plugin_command,
    extractor.plugin_type AS extractor_plugin_type,
    extractor.plugin_category AS extractor_plugin_category,
    extractor.plugin_surrogate_key AS extractor_plugin_surrogate_key,
    loader.plugin_exec_pk AS loader_plugin_exec_pk,
    loader.plugin_started AS loader_plugin_started,
    loader.plugin_ended AS loader_plugin_ended,
    loader.plugin_runtime_ms AS loader_plugin_runtime_ms,
    loader.completion_status AS loader_completion_status,
    loader.event_source AS loader_event_source,
    loader.event_type AS loader_event_type,
    loader.plugin_name AS loader_plugin_name,
    loader.parent_name AS loader_parent_name,
    loader.executable AS loader_executable,
    loader.namespace AS loader_namespace,
    loader.pip_url AS loader_pip_url,
    loader.plugin_variant AS loader_plugin_variant,
    loader.plugin_command AS loader_plugin_command,
    loader.plugin_type AS loader_plugin_type,
    loader.plugin_category AS loader_plugin_category,
    loader.plugin_surrogate_key AS loader_plugin_surrogate_key,
    extractor.cli_command,
    extractor.env_id,
    extractor.env_name,
    extractor.cli_exit_code,
    extractor.meltano_version,
    extractor.num_cpu_cores_available,
    extractor.windows_edition,
    extractor.machine,
    extractor.system_release,
    extractor.is_dev_build,
    extractor.python_version,
    extractor.is_ci_environment,
    extractor.python_implementation,
    extractor.system_name,
    extractor.system_version,
    extractor.project_id,
    extractor.project_first_event_at,
    extractor.project_lifespan_days,
    extractor.is_ephemeral_project_id,
    extractor.is_currently_active,
    extractor.project_id_source,
    extractor.init_project_directory,
    extractor.project_org_name,
    extractor.cloud_provider,
    extractor.execution_location,
    extractor.org_name,
    extractor.pipeline_fk,
    extractor.pipeline_runtime_bin,
    extractor.ip_address_hash,
    extractor.cli_started_ts,
    extractor.cli_finished_ts,
    extractor.cli_runtime_ms,
    extractor.is_active_cli_execution
FROM pair_roll_up
LEFT JOIN {{ ref('fact_plugin_usage') }} AS extractor
    ON pair_roll_up.extractor_plugin_exec_pk = extractor.plugin_exec_pk
LEFT JOIN {{ ref('fact_plugin_usage') }} AS loader
    ON pair_roll_up.loader_plugin_exec_pk = loader.plugin_exec_pk
