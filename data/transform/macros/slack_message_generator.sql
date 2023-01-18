{% macro slack_message_generator() -%}
'\n     • <' || html_url || ' | ' || organization_name || '/' || repo_name || ' #' || GET(split(html_url, '/'), 6)::STRING || '> (*' || author_username || '*) - _' || title || '_'  || CASE WHEN singer_contributions.is_hub_listed THEN '(:melty-flame: < ' || stg_meltanohub__plugins.docs || ' | _MeltanoHub Link_>)\n' ELSE '\n' END
{%- endmacro %}
