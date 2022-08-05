WITH base AS (
    SELECT
        event_count,
        plugin_variant,
        pip_url,
        plugin_type,
        plugin_name,
        parent_name,
        project_id,
        COALESCE(
            cli_command IN ('run', 'elt')
            AND completion_status = 'SUCCESS',
            FALSE
        ) AS is_success_exec,
        event_type,
        plugin_category
    FROM {{ ref('fact_plugin_usage') }}
    WHERE cli_started_ts >= DATEADD(MONTH, -3, CURRENT_DATE)

),

agg_variant AS (
    SELECT
        plugin_variant,
        plugin_type,
        parent_name AS plugin_name,
        COUNT(DISTINCT project_id) AS all_projects,
        COUNT(
            DISTINCT CASE WHEN
                is_success_exec
                THEN project_id END
        ) AS success_projects,
        SUM(
            CASE WHEN is_success_exec
                THEN event_count END
        ) AS success_execs,
        SUM(event_count) AS all_execs
    FROM base
    WHERE event_type = 'unstructured'
    GROUP BY 1, 2, 3
),

agg_pip_url AS (
    SELECT
        pip_url,
        plugin_type,
        COUNT(DISTINCT project_id) AS all_projects,
        COUNT(
            DISTINCT CASE WHEN
                is_success_exec
                THEN project_id END
        ) AS success_projects,
        SUM(
            CASE WHEN
                is_success_exec
                THEN event_count END
        ) AS success_execs,
        SUM(event_count) AS all_execs
    FROM base
    WHERE event_type = 'unstructured'
    GROUP BY 1, 2
),

agg_legacy AS (
    SELECT
        COALESCE(NULLIF(parent_name, 'UNKNOWN'), plugin_name) AS plugin_name,
        COUNT(DISTINCT project_id) AS all_projects,
        COUNT(
            DISTINCT CASE WHEN
                is_success_exec
                THEN project_id END
        ) AS success_projects,
        SUM(
            CASE WHEN
                is_success_exec
                THEN event_count END
        ) AS success_execs,
        SUM(event_count) AS all_execs
    FROM base
    WHERE plugin_category = 'singer'
    GROUP BY 1
)

SELECT
    stg_meltanohub__plugins.name,
    stg_meltanohub__plugins.variant,
    stg_meltanohub__plugins.repo,
    stg_meltanohub__plugins.plugin_type,
    stg_meltanohub__plugins.pip_url,
    stg_meltanohub__plugins.is_default,
    COALESCE(
        agg_variant.all_projects,
        agg_pip_url.all_projects
    ) AS all_projects,
    COALESCE(
        agg_variant.success_projects,
        agg_pip_url.success_projects
    ) AS success_projects,
    COALESCE(
        agg_variant.success_execs,
        agg_pip_url.success_execs
    ) AS success_execs,
    COALESCE(
        agg_variant.all_execs,
        agg_pip_url.all_execs
    ) AS all_execs,
    agg_legacy.all_projects AS legacy_all_projects,
    agg_legacy.success_projects AS legacy_success_projects,
    agg_legacy.success_execs AS legacy_success_execs,
    agg_legacy.all_execs AS legacy_all_execs,
    fact_repo_metrics.created_at_ts AS created_at_timestamp,
    fact_repo_metrics.last_push_ts AS last_push_timestamp,
    fact_repo_metrics.last_updated_ts AS last_updated_timestamp,
    fact_repo_metrics.num_forks::INT AS num_forks,
    fact_repo_metrics.num_open_issues::INT AS num_open_issues,
    fact_repo_metrics.num_stargazers::INT AS num_stargazers,
    fact_repo_metrics.num_watchers::INT AS num_watchers
FROM {{ ref('stg_meltanohub__plugins') }}
LEFT JOIN agg_variant
    ON agg_variant.plugin_name = stg_meltanohub__plugins.name
        AND agg_variant.plugin_type = stg_meltanohub__plugins.plugin_type
        AND agg_variant.plugin_variant = stg_meltanohub__plugins.variant
LEFT JOIN agg_pip_url
    ON agg_pip_url.pip_url = stg_meltanohub__plugins.pip_url
        AND agg_pip_url.plugin_type = stg_meltanohub__plugins.plugin_type
LEFT JOIN {{ ref('fact_repo_metrics') }}
    ON LOWER(stg_meltanohub__plugins.repo) = LOWER(
        'https://github.com/' || fact_repo_metrics.repo_full_name
    )
LEFT JOIN agg_legacy
    ON REPLACE(
        fact_repo_metrics.repo_name,
        'pipelinewise-',
        ''
    ) = agg_legacy.plugin_name
