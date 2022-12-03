{% macro slack_message_generator() -%}
'\n     • <' || html_url || ' | ' || organization_name || '/' || repo_name || ' #' || GET(split(html_url, '/'), 6)::STRING || '> (*' || author_username || '*) ' || CASE WHEN singer_contributions.is_hub_listed THEN ':melty-flame:' ELSE ':singer-logo:' END || ' : _' || title || '_\n'
{%- endmacro %}
