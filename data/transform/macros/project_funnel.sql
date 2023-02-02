{% macro project_funnel(mapping, project_where_filter=None, alt_base_level=None) -%}
-- This macro builds a compounding funnel based on parameterized inputs.
-- Given a mapping of funnel levels and their associated filtering logic this builds SQL
-- that evaluates weekly cohorts with the compounding filters.
--
-- Optionally you can provide a project_where_filter which is a full WHERE clause (including the WHERE)
-- to exclude certain data from the top of the funnel.
--
-- Optionally you can provide an alt_base_level which will add an additional column called
-- alt_base_all that can be used as an alternative base count for % metrics.

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
    {% if project_where_filter %}{{ project_where_filter }}{% endif %}
    

),

agg_base AS (
    SELECT
        cohort_week,
        COUNT(
            DISTINCT project_id
        ) AS base_all,
        {% if alt_base_level %}

            {{ compounding_funnel_filters(
                (mapping.keys() | list).index(alt_base_level) + 1,
                mapping,
                "COUNT(DISTINCT CASE WHEN TRUE",
                "THEN project_id END)"
            ) }} AS alt_base_all,

        {% endif %}


        {% for filter_name, attribs in mapping.items() %}
            {{ compounding_funnel_filters(
                loop.index,
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
    {{ loop.index }} AS funnel_level_index,
    {{ filter_name }} AS funnel_level_value,
    {{ attribs.get('parent_name', 'base_all') }} AS parent_level_value,
    base_all
    {% if alt_base_level %},alt_base_all{% endif %}
FROM agg_base

{% endfor %}

{%- endmacro %}
