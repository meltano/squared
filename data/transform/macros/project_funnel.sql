{% macro project_funnel(mapping, base_where_filter='') -%}

WITH active_executions AS (

    SELECT
        project_id,
        SUM(
            CASE WHEN is_active_cli_execution THEN 1 END
        ) AS active_executions_count
    FROM {{ ref('fact_cli_executions') }}
    GROUP BY 1
),

project_base AS (

    SELECT
        project_dim.*,
        active_executions.active_executions_count,
        DATE_TRUNC(WEEK, project_dim.project_first_event_at) AS cohort_week
    FROM {{ ref('project_dim') }}
    LEFT JOIN active_executions
        ON project_dim.project_id = active_executions.project_id
    {{ base_where_filter }}
    

),

agg_base AS (
    SELECT
        cohort_week,
        COUNT(
            DISTINCT project_id
        ) AS base_all,
        {% for filter_name, attribs in mapping.items() %}
        {{ compounding_funnel_filters(
			loop.index,
			filter_name,
			mapping,
			"COUNT(DISTINCT CASE WHEN TRUE",
			"THEN project_id END)"
		) }} AS {{ filter_name }}
			{%- if not loop.last %},{% endif -%}
		{% endfor %}
    FROM project_base
    GROUP BY 1
)


{% for filter_name, attribs in mapping.items() %}    

{%- if not loop.first %}
UNION ALL
{% endif -%}

SELECT
    cohort_week,
    '{{ loop.index }}' || '_' || '{{ filter_name }}' AS funnel_level,
    {{ filter_name }} AS funnel_level_value,
    {{ attribs.get('parent_name', 'base_all') }} AS parent_level_value,
    base_all
FROM agg_base

{% endfor %}

{%- endmacro %}
