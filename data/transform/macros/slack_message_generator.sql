{% macro slack_message_generator() -%}
'\n     • <' || html_url || ' | ' || organization_name || '/' || repo_name || ' #' || GET(split(html_url, '/'),  array_size(split(html_url, '/'))-1)::STRING || '> - _' || title || '_'  || CASE WHEN singer_contributions.is_hub_listed THEN ' (:melty-flame: < ' || hub_unique.docs || ' | _MeltanoHub Link_>)\n' ELSE '\n' END
{%- endmacro %}
