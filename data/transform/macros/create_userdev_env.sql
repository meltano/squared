{% macro create_userdev_env(db_list=["RAW"], dry_run=True, schema_list=[]) %}

    -- Use Meltano defined USER_PREFIX to be consistent
    {% if not env_var("USER_PREFIX", "") %}
        {{ exceptions.raise_compiler_error("'USER_PREFIX' environment variable must be present to run this macro.") }}
    {% endif %}

    {% set dry_run_script = [] %}

    {% for source_db_name in db_list -%}

        {%- set target_db_name = env_var("USER_PREFIX") + "_" + source_db_name -%}

        {% set get_schemas_sql %}
            SELECT
                SCHEMA_NAME
            FROM {{ source_db_name }}.information_schema.schemata
            WHERE schema_name NOT IN ('INFORMATION_SCHEMA', 'PUBLIC')
        {% endset %}

        -- Run query to retrieve all schemas the current user has access to
        {%- set schemas_to_clone = dbt_utils.get_query_results_as_dict(get_schemas_sql) -%}

        {% for schema in schemas_to_clone['SCHEMA_NAME'] -%}

            {% if schema_list|length == 0 or source_db_name + "." + schema in schema_list %}
                {%- set clone_sql -%}
                    CREATE OR REPLACE SCHEMA {{ target_db_name }}.{{ schema }} CLONE {{ source_db_name }}.{{ schema }};
                {% endset %}

                {% if dry_run %}
                    -- Dry run queries are logged later
                    {{ dry_run_script.append( clone_sql.replace('\n', '') ) }}
                {% else %}
                    {{ (log("Cloning " ~ schema ~ " from " ~ source_db_name ~ " to " ~ target_db_name, info=True)) }}
                    {% set results = run_query(clone_sql) %}
                    {{ log(results[0][0], info=True)}}
                {% endif %}
            {% endif %}
        {% endfor %}
    {% endfor %}

    -- Log dry run script
    {% if dry_run %}
        {{ (log(
            'Either execute this clone script manually or rerun this macro using the `dry_run=False` argument.\n\n'
            ~ '\n'.join(dry_run_script) ~ '\n',
            info=True
        )) }}
    {% endif %}

{% endmacro %}