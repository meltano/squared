WITH base_singer AS (
    SELECT
        flat.value::STRING AS plugin_name,
        cmd_parsed_all.command
    FROM {{ ref('cmd_parsed_all') }},
        LATERAL FLATTEN(input=>singer_plugins) AS flat
    WHERE cmd_parsed_all.command_type = 'plugin'
),

base_other AS (
    SELECT
        flat.value::STRING AS plugin_name,
        cmd_parsed_all.command
    FROM {{ ref('cmd_parsed_all') }},
        LATERAL FLATTEN(input=>other_plugins) AS flat
    WHERE cmd_parsed_all.command_type = 'plugin'
)

SELECT DISTINCT
    COALESCE(
        hash_lookup.unhashed_value,
        SHA2_HEX(base_singer.plugin_name)
    ) AS plugin_name,
    base_singer.command,
    'singer' AS plugin_category,
    COALESCE(stg_meltanohub__plugins.plugin_type, 'UNKNOWN') AS plugin_type,
    NULL AS plugin_command
FROM base_singer
LEFT JOIN {{ ref('hash_lookup') }}
    ON SHA2_HEX(base_singer.plugin_name) = hash_lookup.hash_value
        AND hash_lookup.category = 'plugin_name'
LEFT JOIN {{ ref('stg_meltanohub__plugins') }}
    ON base_singer.plugin_name = stg_meltanohub__plugins.name

-- Mappers are included in the singer_plugins list

UNION ALL

SELECT DISTINCT
    COALESCE(
        hash_lookup.unhashed_value,
        SHA2_HEX(base_other.plugin_name)
    ) AS plugin_name,
    base_other.command,
    CASE
        WHEN base_other.plugin_name LIKE 'dbt-%' THEN 'dbt'
        ELSE
            SPLIT_PART(base_other.plugin_name, ':', 1)
    END
    AS plugin_category,
    COALESCE(stg_meltanohub__plugins.plugin_type, 'UNKNOWN') AS plugin_type,
    SPLIT_PART(base_other.plugin_name, ':', 2) AS plugin_command
FROM base_other
LEFT JOIN {{ ref('hash_lookup') }}
    ON SHA2_HEX(
        SPLIT_PART(base_other.plugin_name, ':', 1)
    ) = hash_lookup.hash_value
    AND hash_lookup.category = 'plugin_name'
LEFT JOIN {{ ref('stg_meltanohub__plugins') }}
    ON SPLIT_PART(base_other.plugin_name, ':', 1) = stg_meltanohub__plugins.name
