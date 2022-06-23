with base as (
    select
        distinct
        plugin.value AS plugin_dict,
        plugin.value:command::string as command,
        plugin.value:category::string as category,
        plugin.value:executable_hash::string as executable_hash,
        plugin.value:name_hash::string as name_hash,
        plugin.value:namespace_hash::string as namespace_hash,
        plugin.value:pip_url_hash::string as pip_url_hash,
        plugin.value:variant_name_hash::string as variant_name_hash,
        plugin.value:parent_name_hash::string as parent_name_hash
    FROM {{ ref('unstructured_executions') }},
    LATERAL FLATTEN(input => COALESCE(plugins, [''])) as plugin_list,
    LATERAL FLATTEN(input => COALESCE(plugin_list.value::variant, [''])) as plugin
)

select
    {{ dbt_utils.surrogate_key(
        ['plugin_dict']
    ) }} AS plugin_surrogate_key,
    *
from base
