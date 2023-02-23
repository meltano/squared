WITH base AS (
    SELECT
        unstruct_plugins_base.plugin_surrogate_key,
        unstruct_plugins_base.category AS plugin_type,
        COALESCE(
            h1.unhashed_value, unstruct_plugins_base.name_hash
        ) AS plugin_name,
        COALESCE(
            h2.unhashed_value, unstruct_plugins_base.parent_name_hash
        ) AS parent_name,
        COALESCE(
            h3.unhashed_value, unstruct_plugins_base.executable_hash
        ) AS executable,
        COALESCE(
            h4.unhashed_value, unstruct_plugins_base.namespace_hash
        ) AS namespace,
        COALESCE(
            h5.unhashed_value, unstruct_plugins_base.pip_url_hash
        ) AS pip_url,
        COALESCE(
            h6.unhashed_value, unstruct_plugins_base.variant_name_hash
        ) AS variant_name,
        COALESCE(
            h7.unhashed_value, SHA2_HEX(unstruct_plugins_base.command)
        ) AS command
    FROM {{ ref('unstruct_plugins_base') }}
    LEFT JOIN {{ ref('hash_lookup') }} AS h1
        ON unstruct_plugins_base.name_hash = h1.hash_value
            AND h1.category = 'plugin_name'
    LEFT JOIN {{ ref('hash_lookup') }} AS h2
        ON unstruct_plugins_base.parent_name_hash = h2.hash_value
            AND h2.category = 'plugin_name'
    LEFT JOIN {{ ref('hash_lookup') }} AS h3
        ON unstruct_plugins_base.executable_hash = h3.hash_value
            AND h3.category = 'plugin_executable'
    LEFT JOIN {{ ref('hash_lookup') }} AS h4
        ON unstruct_plugins_base.namespace_hash = h4.hash_value
            AND h4.category = 'plugin_namespace'
    LEFT JOIN {{ ref('hash_lookup') }} AS h5
        ON unstruct_plugins_base.pip_url_hash = h5.hash_value
            AND h5.category = 'plugin_pip_url'
    LEFT JOIN {{ ref('hash_lookup') }} AS h6
        ON unstruct_plugins_base.variant_name_hash = h6.hash_value
            AND h6.category = 'plugin_variant'
    LEFT JOIN {{ ref('hash_lookup') }} AS h7
        ON SHA2_HEX(unstruct_plugins_base.command) = h7.hash_value
            AND h7.category = 'plugin_command'
)

SELECT
    *,
    CASE
        WHEN plugin_type IN ('extractors', 'loaders', 'mappers') THEN 'singer'
        -- This includes dbt-osmosis and dbt-dry-run
        WHEN
            plugin_type IN (
                'transformers', 'utilities'
            ) AND plugin_name LIKE '%dbt%'
            THEN 'dbt'
        ELSE parent_name END AS plugin_category
FROM base
