WITH base AS (
    SELECT
        fact_plugin_usage.event_count,
        fact_plugin_usage.plugin_variant,
        fact_plugin_usage.pip_url,
        fact_plugin_usage.plugin_type,
        fact_plugin_usage.plugin_name,
        fact_plugin_usage.parent_name,
        fact_plugin_usage.project_id,
        fact_plugin_usage.event_type,
        fact_plugin_usage.plugin_category,
        COALESCE(
            fact_plugin_usage.cli_command IN ('run', 'elt', 'invoke'),
            FALSE
        ) AS is_exec,
        COALESCE(
            fact_plugin_usage.completion_status = 'SUCCESS',
            FALSE
        ) AS is_success
    FROM {{ ref('fact_plugin_usage') }}
    LEFT JOIN {{ ref('project_dim') }}
        ON fact_plugin_usage.project_id = project_dim.project_id
    WHERE
        COALESCE(
            fact_plugin_usage.cli_started_ts, fact_plugin_usage.cli_finished_ts
        ) >= DATEADD(MONTH, -3, CURRENT_DATE)
        AND project_dim.project_id_source != 'random'
        AND project_dim.is_ci_only = FALSE
        AND project_dim.has_opted_out = FALSE
        AND project_dim.project_lifespan_mins > 5
),

agg_all_by_name AS (
    SELECT
        CASE
            WHEN
                parent_name != 'UNKNOWN' AND LENGTH(
                    parent_name
                ) != 64 THEN parent_name
            ELSE plugin_name
        END AS plugin_name,
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
),

unstruct_base AS (

    SELECT
        stg_meltanohub__plugins.name,
        stg_meltanohub__plugins.plugin_type,
        stg_meltanohub__plugins.variant,
        base.is_success,
        base.is_exec,
        base.project_id,
        base.event_count
    FROM {{ ref('stg_meltanohub__plugins') }}
    -- Usage is attributed if the variant matches whats on the hub or if the
    -- pip_url matches but the variant does not. That accounts for the
    -- `original` variant case where the python package is the same but the
    -- variant doesnt reflect it.
    LEFT JOIN base
        ON (
            base.plugin_name = stg_meltanohub__plugins.name
            AND base.plugin_type = stg_meltanohub__plugins.plugin_type
            AND base.plugin_variant = stg_meltanohub__plugins.variant
        ) OR (
            base.plugin_name = stg_meltanohub__plugins.name
            AND base.plugin_type = stg_meltanohub__plugins.plugin_type
            AND base.pip_url = stg_meltanohub__plugins.pip_url
            AND base.plugin_variant != stg_meltanohub__plugins.variant
        )
    WHERE base.event_type = 'unstructured'

),

agg_unstruct_by_name AS (
    SELECT
        plugin_name,
        plugin_type,
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
    GROUP BY 1, 2
),

agg_unstruct_by_variant AS (
    SELECT
        name,
        plugin_type,
        variant,
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
    FROM unstruct_base
    GROUP BY 1, 2, 3
),

final AS (

    SELECT
        stg_meltanohub__plugins.name,
        stg_meltanohub__plugins.variant,
        stg_meltanohub__plugins.repo,
        stg_meltanohub__plugins.plugin_type,
        stg_meltanohub__plugins.pip_url,
        stg_meltanohub__plugins.is_default,
        COALESCE(agg_all_by_name.all_projects, 0) AS all_projects_by_name,
        COALESCE(
            agg_all_by_name.success_projects, 0
        ) AS success_projects_by_name,
        COALESCE(
            agg_unstruct_by_name.all_projects, 0
        ) AS all_projects_unstruct_by_name,
        COALESCE(
            agg_unstruct_by_name.success_projects, 0
        ) AS success_projects_unstruct_by_name,
        COALESCE(
            agg_unstruct_by_variant.all_projects, 0
        ) AS all_projects_unstruct_by_variant,
        COALESCE(
            agg_unstruct_by_variant.success_projects, 0
        ) AS success_projects_unstruct_by_variant,
        COALESCE(agg_all_by_name.all_execs, 0) AS all_execs_by_name,
        COALESCE(agg_all_by_name.success_execs, 0) AS success_execs_by_name,
        COALESCE(
            agg_unstruct_by_name.all_execs, 0
        ) AS all_execs_unstruct_by_name,
        COALESCE(
            agg_unstruct_by_name.success_execs, 0
        ) AS success_execs_unstruct_by_name,
        COALESCE(
            agg_unstruct_by_variant.all_execs, 0
        ) AS all_execs_unstruct_by_variant,
        COALESCE(
            agg_unstruct_by_variant.success_execs, 0
        ) AS success_execs_unstruct_by_variant
    FROM {{ ref('stg_meltanohub__plugins') }}
    LEFT JOIN agg_unstruct_by_variant
        ON agg_unstruct_by_variant.name = stg_meltanohub__plugins.name
            AND agg_unstruct_by_variant.plugin_type
            = stg_meltanohub__plugins.plugin_type
            AND agg_unstruct_by_variant.variant
            = stg_meltanohub__plugins.variant
    LEFT JOIN agg_unstruct_by_name
        ON agg_unstruct_by_name.plugin_name
            = stg_meltanohub__plugins.name
            AND agg_unstruct_by_name.plugin_type
            = stg_meltanohub__plugins.plugin_type
    LEFT JOIN {{ ref('fact_repo_metrics') }}
        ON LOWER(stg_meltanohub__plugins.repo) = LOWER(
            'https://github.com/' || fact_repo_metrics.repo_full_name
        )
    LEFT JOIN agg_all_by_name
        ON REPLACE(
            fact_repo_metrics.repo_name,
            'pipelinewise-',
            ''
        ) = agg_all_by_name.plugin_name
)

SELECT
    *,
    all_projects_unstruct_by_variant AS all_projects,
    all_execs_unstruct_by_variant AS all_execs
FROM final
