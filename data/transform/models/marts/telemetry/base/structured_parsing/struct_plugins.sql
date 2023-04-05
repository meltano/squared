WITH base_singer AS (
    SELECT
        flat.value::STRING AS plugin_name,
        cmd_parsed_all.command,
        cmd_parsed_all.singer_mapper_plugins
    FROM {{ ref('cmd_parsed_all') }},
        LATERAL FLATTEN(input => singer_plugins) AS flat
    WHERE cmd_parsed_all.command_type = 'plugin'
),

base_other AS (
    SELECT
        flat.value::STRING AS plugin_name,
        cmd_parsed_all.command
    FROM {{ ref('cmd_parsed_all') }},
        LATERAL FLATTEN(input => other_plugins) AS flat
    WHERE cmd_parsed_all.command_type = 'plugin'
)

SELECT DISTINCT
    COALESCE(
        hash_lookup.unhashed_value,
        SHA2_HEX(base_singer.plugin_name)
    ) AS plugin_name,
    base_singer.command,
    'singer' AS plugin_category,
    COALESCE(
        stg_meltanohub__plugins.plugin_type,
        CASE
            WHEN
                base_singer.plugin_name LIKE 'tap-%'
                OR base_singer.plugin_name LIKE 'tap_%'
                OR base_singer.plugin_name LIKE 'pipelinewise-tap-%'
                THEN 'extractors'
            WHEN
                base_singer.plugin_name LIKE 'target-%'
                OR base_singer.plugin_name LIKE 'target_%'
                OR base_singer.plugin_name LIKE 'pipelinewise-target-%'
                THEN 'loaders'
            WHEN
                ARRAY_CONTAINS(
                    base_singer.plugin_name::VARIANT,
                    base_singer.singer_mapper_plugins
                )
                THEN 'mappers'
            ELSE 'UNKNOWN'
        END
    ) AS plugin_type,
    NULL AS plugin_command
FROM base_singer
LEFT JOIN {{ ref('hash_lookup') }}
    ON
        SHA2_HEX(base_singer.plugin_name) = hash_lookup.hash_value
        AND hash_lookup.category = 'plugin_name'
LEFT JOIN {{ ref('stg_meltanohub__plugins') }}
    ON base_singer.plugin_name = stg_meltanohub__plugins.name

-- Mappers are included in the singer_plugins list

UNION ALL

SELECT DISTINCT
    COALESCE(
        h1.unhashed_value,
        SHA2_HEX(base_other.plugin_name)
    ) AS plugin_name,
    base_other.command,
    CASE
        WHEN base_other.plugin_name LIKE 'dbt-%' THEN 'dbt'
        ELSE COALESCE(stg_meltanohub__plugins.name, 'UNKNOWN')
    END
    AS plugin_category,
    COALESCE(stg_meltanohub__plugins.plugin_type, 'UNKNOWN') AS plugin_type,
    COALESCE(
        h2.unhashed_value,
        SHA2_HEX(SPLIT_PART(base_other.plugin_name, ':', 2))
    ) AS plugin_command
FROM base_other
LEFT JOIN {{ ref('hash_lookup') }} AS h1
    ON
        SHA2_HEX(
            SPLIT_PART(base_other.plugin_name, ':', 1)
        ) = h1.hash_value
        AND h1.category = 'plugin_name'
LEFT JOIN {{ ref('hash_lookup') }} AS h2
    ON
        SHA2_HEX(SPLIT_PART(base_other.plugin_name, ':', 2)) = h2.hash_value
        AND h2.category = 'plugin_command'
LEFT JOIN {{ ref('stg_meltanohub__plugins') }}
    ON SPLIT_PART(base_other.plugin_name, ':', 1) = stg_meltanohub__plugins.name
WHERE stg_meltanohub__plugins.plugin_type != 'transforms'
