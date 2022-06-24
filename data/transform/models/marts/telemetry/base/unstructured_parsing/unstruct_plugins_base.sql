WITH base AS (
    SELECT DISTINCT
        plugin.value AS plugin_dict,
        plugin.value:command::STRING AS command,
        plugin.value:category::STRING AS category,
        plugin.value:executable_hash::STRING AS executable_hash,
        plugin.value:name_hash::STRING AS name_hash,
        plugin.value:namespace_hash::STRING AS namespace_hash,
        plugin.value:pip_url_hash::STRING AS pip_url_hash,
        plugin.value:variant_name_hash::STRING AS variant_name_hash,
        plugin.value:parent_name_hash::STRING AS parent_name_hash
    FROM {{ ref('unstructured_executions') }},
        LATERAL FLATTEN(input => plugins) AS plugin_list, -- noqa: L025, L031
        -- noqa: L031
        LATERAL FLATTEN(input => plugin_list.value::VARIANT) AS plugin
)

SELECT
    {{ dbt_utils.surrogate_key(
        ['plugin_dict']
    ) }} AS plugin_surrogate_key,
    *
FROM base
