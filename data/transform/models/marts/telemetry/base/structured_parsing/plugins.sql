SELECT
    DISTINCT
    command,
    value::string AS plugin_name,
    'singer' AS plugin_category
FROM {{ ref('structured_parsing_combined') }},
lateral flatten(input=>singer_plugins)
WHERE structured_parsing_combined.command_type = 'plugin'

UNION ALL

SELECT
    DISTINCT
    command,
    value::string AS plugin_name,
    CASE
        WHEN value::STRING LIKE 'dbt-%' THEN 'dbt'
    ELSE
        split_part(value::string, ':', 1)
    END
    AS plugin_category
FROM USERDEV_PREP.PNADOLNY_WORKSPACE.structured_parsing_combined,
lateral flatten(input=>other_plugins)
WHERE structured_parsing_combined.command_type = 'plugin'