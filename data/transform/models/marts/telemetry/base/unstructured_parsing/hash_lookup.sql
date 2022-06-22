select
    distinct
    plugin_name as unhashed_value,
    SHA2_HEX(plugin_name) AS hash_value
from {{ ref('plugins') }}

union

select
    distinct
    f.value::string as unhashed_value,
    SHA2_HEX(f.value) AS hash_value
from table(flatten(input => parse_json('["prod", "staging", "dev", "cicd"]'))) f
