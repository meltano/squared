with base as (
    select
        distinct
        plugins.value AS plugin_dict,
        plugins.value:command::string as command,
        plugins.value:category::string as category,
        plugins.value:executable_hash::string as executable_hash,
        plugins.value:name_hash::string as name_hash,
        plugins.value:namespace_hash::string as namespace_hash,
        plugins.value:pip_url_hash::string as pip_url_hash,
        plugins.value:variant_name_hash::string as variant_name_hash,
        plugins.value:parent_name_hash::string as parent_name_hash
    from {{ ref('stg_snowplow__events') }},
    LATERAL FLATTEN(input => parse_json(contexts::variant):data) as context,
    LATERAL FLATTEN(input => context.value:data:plugins) as plugins
    where event = 'unstruct'
)

select
    {{ dbt_utils.surrogate_key(
        ['plugin_dict']
    ) }} AS plugin_surrogate_key,
    *
from base
