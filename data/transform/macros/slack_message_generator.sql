{% macro slack_message_generator() -%}
'\n     • <' || html_url || ' | ' || organization_name || '/' || repo_name || ' #' || GET(split(html_url, '/'), 6)::STRING || '> (*' || author_username || '*): _' || title || '_\n'
{%- endmacro %}
