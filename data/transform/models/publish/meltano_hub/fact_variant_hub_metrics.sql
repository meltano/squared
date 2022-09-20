WITH base AS (
    SELECT
        event_count,
        plugin_variant,
        pip_url,
        plugin_type,
        plugin_name,
        parent_name,
        project_id,
        event_type,
        plugin_category,
        COALESCE(
            cli_command IN ('run', 'elt'),
            FALSE
        ) AS is_exec,
        COALESCE(
            completion_status = 'SUCCESS',
            FALSE
        ) AS is_success
    FROM {{ ref('fact_plugin_usage') }}
    WHERE COALESCE(cli_started_ts, cli_finished_ts) >= DATEADD(MONTH, -3, CURRENT_DATE)

),

agg_variant AS (
    SELECT
        plugin_variant,
        plugin_type,
        parent_name AS plugin_name,
        pip_url,
        COUNT(DISTINCT project_id) AS all_projects,
        COUNT(
            DISTINCT CASE WHEN
                is_success AND is_exec
                THEN project_id END
        ) AS success_projects,
        SUM(
            CASE WHEN is_success AND is_exec
                THEN event_count END
        ) AS success_execs,
        SUM(
            CASE WHEN is_exec
                THEN event_count END
        ) AS all_execs
    FROM base
    WHERE event_type = 'unstructured'
    GROUP BY 1, 2, 3, 4
),

agg_hub_matches AS (

    SELECT
        stg_meltanohub__plugins.name,
        stg_meltanohub__plugins.variant,
        stg_meltanohub__plugins.plugin_type,
        SUM(agg_variant.all_projects) AS all_projects,
        SUM(agg_variant.success_projects) AS success_projects,
        SUM(agg_variant.all_execs) AS all_execs,
        SUM(agg_variant.success_execs) AS success_execs
    FROM {{ ref('stg_meltanohub__plugins') }}
    -- Usage is attributed if the variant matches whats on the hub or if the
    -- pip_url matches but the variant does not. That accounts for the
    -- `original` variant case where the python package is the same but the
    -- variant doesnt reflect it.
    LEFT JOIN agg_variant
        ON (
            agg_variant.plugin_name = stg_meltanohub__plugins.name
            AND agg_variant.plugin_type = stg_meltanohub__plugins.plugin_type
            AND agg_variant.plugin_variant = stg_meltanohub__plugins.variant
        ) OR (
            agg_variant.plugin_name = stg_meltanohub__plugins.name
            AND agg_variant.plugin_type = stg_meltanohub__plugins.plugin_type
            AND agg_variant.pip_url = stg_meltanohub__plugins.pip_url
            AND agg_variant.plugin_variant != stg_meltanohub__plugins.variant
        )
    GROUP BY 1, 2, 3
),

agg_legacy AS (
    SELECT
        COALESCE(NULLIF(parent_name, 'UNKNOWN'), plugin_name) AS plugin_name,
        COUNT(DISTINCT project_id) AS all_projects,
        COUNT(
            DISTINCT CASE WHEN
                is_success AND is_exec
                THEN project_id END
        ) AS success_projects,
        SUM(
            CASE WHEN is_success AND is_exec
                THEN event_count END
        ) AS success_execs,
        SUM(
            CASE WHEN is_exec
                THEN event_count END
        ) AS all_execs
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
    fact_repo_metrics.num_watchers::INT AS num_watchers,
    agg_hub_matches.all_projects,
    agg_hub_matches.success_projects,
    agg_hub_matches.success_execs,
    agg_hub_matches.all_execs
FROM {{ ref('stg_meltanohub__plugins') }}
LEFT JOIN agg_hub_matches
    ON agg_hub_matches.name = stg_meltanohub__plugins.name
        AND agg_hub_matches.plugin_type = stg_meltanohub__plugins.plugin_type
        AND agg_hub_matches.variant = stg_meltanohub__plugins.variant
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
