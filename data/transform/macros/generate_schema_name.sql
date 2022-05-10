{% macro generate_schema_name(custom_schema_name, node) -%}

    {% if custom_schema_name %}
        {%- set new_schema_name = custom_schema_name -%}
    {% else %}
        {%- set new_schema_name = target.schema -%}
    {% endif %}



    {%- if env_var("MELTANO_ENVIRONMENT") in ["userdev", "cicd"] -%}

        {{ env_var("DBT_SNOWFLAKE_TARGET_SCHEMA_PREFIX") + new_schema_name | trim }}

    {% else %}

        {{ new_schema_name | trim }}

    {% endif %}


{%- endmacro %}