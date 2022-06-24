WITH base AS (
    SELECT
        unstruct_plugins_base.plugin_surrogate_key,
        unstruct_plugins_base.command,
        unstruct_plugins_base.category AS plugin_type,
        h1.unhashed_value AS plugin_name,
        h2.unhashed_value AS parent_name,
        h3.unhashed_value AS executable,
        h4.unhashed_value AS namespace,
        h5.unhashed_value AS pip_url,
        h6.unhashed_value AS variant_name
    FROM {{ ref('unstruct_plugins_base') }}
    LEFT JOIN {{ ref('hash_lookup') }} AS h1
        ON unstruct_plugins_base.name_hash = h1.hash_value
    LEFT JOIN {{ ref('hash_lookup') }} AS h2
        ON unstruct_plugins_base.parent_name_hash = h2.hash_value
    LEFT JOIN {{ ref('hash_lookup') }} AS h3
        ON unstruct_plugins_base.executable_hash = h3.hash_value
    LEFT JOIN {{ ref('hash_lookup') }} AS h4
        ON unstruct_plugins_base.namespace_hash = h4.hash_value
    LEFT JOIN {{ ref('hash_lookup') }} AS h5
        ON unstruct_plugins_base.pip_url_hash = h5.hash_value
    LEFT JOIN {{ ref('hash_lookup') }} AS h6
        ON unstruct_plugins_base.variant_name_hash = h6.hash_value
)

SELECT
    *,
    CASE
        WHEN plugin_type IN ('extractors', 'loaders', 'mappers') THEN 'singer'
        WHEN plugin_type = 'transformers' AND plugin_name LIKE '%dbt%'
            THEN 'dbt'
        ELSE parent_name END AS plugin_category
FROM base
