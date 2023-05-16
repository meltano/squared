{% macro feature_usage_macro(cte_list) -%}

    {% for cte in cte_list %}
        {%- if not loop.first %}
        UNION ALL
        {% endif -%}

        SELECT
            feature_id,
            execution_id
        FROM {{ cte }}
    {% endfor %}

{%- endmacro %}
