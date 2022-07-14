SELECT DISTINCT
    flat.value::STRING AS plugin_name,
    cmd_parsed_all.command,
    'singer' AS plugin_category
FROM {{ ref('cmd_parsed_all') }},
    LATERAL FLATTEN(input=>singer_plugins) AS flat
WHERE cmd_parsed_all.command_type = 'plugin'
-- Mappers are included in the singer_plugins list

UNION ALL

SELECT DISTINCT
    flat.value::STRING AS plugin_name,
    cmd_parsed_all.command,
    CASE
        WHEN flat.value::STRING LIKE 'dbt-%' THEN 'dbt'
        ELSE
            SPLIT_PART(flat.value::STRING, ':', 1)
    END
    AS plugin_category
FROM {{ ref('cmd_parsed_all') }},
    LATERAL FLATTEN(input=>other_plugins) AS flat
WHERE cmd_parsed_all.command_type = 'plugin'
