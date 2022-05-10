{% macro generate_schema_name(custom_schema_name, node) -%}

    {% if custom_schema_name %}
        {%- set new_schema_name = custom_schema_name -%}
    {% else %}
        {%- set new_schema_name = target.schema -%}
    {% endif %}



    {%- if node.database.startswith("USERDEV") -%}

        {{ env_var("USER_PREFIX") + "_" + new_schema_name | trim }}

    {% else %}

        {{ new_schema_name | trim }}

    {% endif %}


{%- endmacro %}