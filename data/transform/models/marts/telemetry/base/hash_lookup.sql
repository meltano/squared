WITH base AS (

    SELECT DISTINCT
        name AS unhashed_value,
        SHA2_HEX(name) AS hash_value,
        'plugin_name' AS category
    FROM {{ ref('stg_meltanohub__plugins') }}

    UNION ALL

    SELECT DISTINCT
        namespace AS unhashed_value,
        SHA2_HEX(namespace) AS hash_value,
        'plugin_namespace' AS category
    FROM {{ ref('stg_meltanohub__plugins') }}

    UNION ALL

    SELECT DISTINCT
        executable AS unhashed_value,
        SHA2_HEX(executable) AS hash_value,
        'plugin_executable' AS category
    FROM {{ ref('stg_meltanohub__plugins') }}
    WHERE executable IS NOT NULL

    UNION ALL

    SELECT DISTINCT
        pip_url AS unhashed_value,
        SHA2_HEX(pip_url) AS hash_value,
        'plugin_pip_url' AS category
    FROM {{ ref('stg_meltanohub__plugins') }}

    UNION ALL

    SELECT DISTINCT
        variant AS unhashed_value,
        SHA2_HEX(variant) AS hash_value,
        'plugin_variant' AS category
    FROM {{ ref('stg_meltanohub__plugins') }}

    UNION ALL

    SELECT
        'original' AS unhashed_value,
        SHA2_HEX('original') AS hash_value,
        'plugin_variant' AS category

    UNION ALL

    SELECT DISTINCT
        command.value::STRING AS unhashed_value,
        SHA2_HEX(command.value::STRING) AS hash_value,
        'plugin_command' AS category
    FROM {{ ref('stg_meltanohub__plugins') }},
        LATERAL FLATTEN(input=>OBJECT_KEYS(commands)) AS command
    WHERE stg_meltanohub__plugins.commands IS NOT NULL

    UNION ALL

    SELECT
        f.value::STRING AS unhashed_value,
        SHA2_HEX(f.value) AS hash_value,
        'environment' AS category
    FROM
        TABLE(
            FLATTEN(
                input => PARSE_JSON(
                    '["prod", "staging", "dev", "cicd", "development", \
                    "production", "ci", "stage"]'
                )
            )
        ) AS f

    UNION ALL

    SELECT
        exception_message AS unhashed_value,
        SHA2_HEX(exception_message) AS hash_value,
        'runtime_error' AS category
    FROM {{ ref('runtime_exceptions') }}

)

SELECT
    {{ dbt_utils.surrogate_key(
        ['hash_value', 'category']
    ) }} AS hash_value_id,
    unhashed_value,
    hash_value,
    category
FROM base
