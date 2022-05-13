{% macro clear_ci_schemas() %}

    {% for ci_database in ['CICD_RAW', 'CICD_PREP', 'CICD_PROD'] -%}

        {% set get_schemas_sql %}
            SELECT
                SCHEMA_NAME
            FROM {{ ci_database }}.information_schema.schemata
            WHERE schema_name NOT IN ('INFORMATION_SCHEMA', 'PUBLIC')
            AND CREATED <= DATEADD('day', -7, CURRENT_DATE)
        {% endset %}

        {%- set schemas_to_destroy = dbt_utils.get_query_results_as_dict(get_schemas_sql) -%}

        {% for schema in schemas_to_destroy['SCHEMA_NAME'] -%}

            {%- set drop_sql -%}
                DROP SCHEMA {{ ci_database }}.{{ schema }};
            {% endset %}

            {{ (log(drop_sql, info=True)) }}
            {% set results = run_query(drop_sql) %}
            {{ log(results[0][0], info=True)}}
        {% endfor %}

    {% endfor %}

{% endmacro %}