{% macro github_activity_slack_message_generator() -%}
'\n     • <' || contribution_url || ' | ' || repo_full_name || ' #' || contribution_number || '> (*' || author_username || '*) at ' || created_at_ts || ' UTC' || '\n' 
{%- endmacro %}
