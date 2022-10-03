{% macro funnel_filter(filter_level) -%}
    {% set filters = [
        "has_opted_out = FALSE",
        "ARRAY_CONTAINS( 'add'::VARIANT, cli_command_array ) OR ARRAY_CONTAINS( 'install'::VARIANT, cli_command_array )",
        "is_exec_event = TRUE",
        "ARRAY_SIZE( pipeline_array ) > 0",
        "ARRAY_CONTAINS( 'SUCCESS'::VARIANT, pipe_completion_statuses )",
        "project_lifespan_days >= 1",
        "project_lifespan_days >= 7",
        "is_currently_active = TRUE"
        ]
    %}
    project_id_source != 'random'
    {% for value in filters[:filter_level] %}
            AND {{ value }}
    {% endfor %}
{%- endmacro %}
