WITH base AS (
    SELECT DISTINCT
        plugin_name AS unhashed_value,
        SHA2_HEX(plugin_name) AS hash_value
    FROM {{ ref('struct_plugins') }}

    UNION

    SELECT
        f.value::STRING AS unhashed_value,
        SHA2_HEX(f.value) AS hash_value
    FROM
        TABLE(
            FLATTEN(
                input => PARSE_JSON(
                    '["prod", "staging", "dev", "cicd", "development", \
                    "production", "ci", "stage"]'
                )
            )
        ) AS f

    UNION

    SELECT
        f.value::STRING AS unhashed_value,
        SHA2_HEX(f.value) AS hash_value
    FROM
        TABLE(
            FLATTEN(
                input => PARSE_JSON(
                    '["apache", "singer-io", "transferwise", "meltano", \
                    "meltanolabs", "bytecodeio", "fishtown-analytics", \
                    "Mashey", "hotgluexyz", "Matatika", "Pathlight", \
                    "dbt-labs", "sqlfluff", "great-expectations", "dataops-tk", \
                    "anelendata", "AutoIDM", "datateer", "adswerve", \
                    "coeff", "shrutikaponde-vc", "datadotworld", "andyh1203", \
                    "prontopro", "estrategiahq"]'
                )
            )
        ) AS f
)

SELECT DISTINCT
    unhashed_value,
    hash_value
FROM base
