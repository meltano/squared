{% macro funnel_filter(stop_index, name, mapping) -%}
    COUNT(DISTINCT CASE WHEN project_id_source != 'random'
    {% for filter_name, attribs in mapping.items() %}
        {% if loop.index <= stop_index %}
            AND {{ attribs['query'] }}
        {%endif%}
    {% endfor %}
    THEN project_id END)
{%- endmacro %}
