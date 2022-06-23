with base as (
    select
        unstruct_plugins_base.plugin_surrogate_key,
        unstruct_plugins_base.command,
        unstruct_plugins_base.category AS plugin_type,
        h1.unhashed_value AS plugin_name,
        h2.unhashed_value as parent_name,
        h3.unhashed_value as executable,
        h4.unhashed_value as namespace,
        h5.unhashed_value as pip_url,
        h6.unhashed_value as variant_name
    from {{ ref('unstruct_plugins_base') }}
    left join {{ ref('hash_lookup') }} as h1
        on unstruct_plugins_base.name_hash = h1.hash_value
    left join {{ ref('hash_lookup') }} as h2
        on unstruct_plugins_base.parent_name_hash = h2.hash_value
    left join {{ ref('hash_lookup') }} as h3
        on unstruct_plugins_base.executable_hash = h3.hash_value
    left join {{ ref('hash_lookup') }} as h4
        on unstruct_plugins_base.namespace_hash = h4.hash_value
    left join {{ ref('hash_lookup') }} as h5
        on unstruct_plugins_base.pip_url_hash = h5.hash_value
    left join {{ ref('hash_lookup') }} as h6
        on unstruct_plugins_base.variant_name_hash = h6.hash_value
)
select
    *,
    case
        when plugin_type in ('extractors', 'loaders', 'mappers') then 'singer'
        -- TODO: think about this more, should it be "LIKE 'dbt-%' THEN 'dbt'" to be more future proof or could we miss some dbt plugins
        when plugin_type = 'transformers' THEN 'dbt'
        else parent_name end as plugin_category
from base
