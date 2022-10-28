{% macro slack_message_generator() -%}
'\n     • <' || html_url || ' | ' || organization_name || '/' || repo_name || ' #' || GET(split(html_url, '/'), 6)::STRING || '> - _' || LEFT(title, 25) || '..._ by *' || author_username || '* \n'
{%- endmacro %}
