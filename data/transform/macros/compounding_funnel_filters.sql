{% macro funnel_filter(stop_index, name, mapping, start, end) -%}
    {{ start }}
    {% for filter_name, attribs in mapping.items() %}
        {% if loop.index <= stop_index %}
            AND {{ attribs['filter'] }}
        {%endif%}
    {% endfor %}
    {{ end }}
{%- endmacro %}
