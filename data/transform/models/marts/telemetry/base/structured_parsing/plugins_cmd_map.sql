SELECT DISTINCT
    cmd_parsed_all.command,
    flat.value::STRING AS plugin_name,
    'singer' AS plugin_category
FROM {{ ref('cmd_parsed_all') }},
    LATERAL FLATTEN(input=>singer_plugins) AS flat
WHERE cmd_parsed_all.command_type = 'plugin'

UNION ALL

SELECT DISTINCT
    cmd_parsed_all.command,
    flat.value::STRING AS plugin_name,
    CASE
        WHEN flat.value::STRING LIKE 'dbt-%' THEN 'dbt'
        ELSE
            SPLIT_PART(flat.value::STRING, ':', 1)
    END
    AS plugin_category
FROM {{ ref('cmd_parsed_all') }},
    LATERAL FLATTEN(input=>other_plugins) AS flat
WHERE cmd_parsed_all.command_type = 'plugin'
