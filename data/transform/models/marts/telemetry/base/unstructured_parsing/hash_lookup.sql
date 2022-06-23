select
    distinct
    plugin_name as unhashed_value,
    SHA2_HEX(plugin_name) AS hash_value
from {{ ref('plugins_cmd_map') }}

union

select
    distinct
    f.value::string as unhashed_value,
    SHA2_HEX(f.value) AS hash_value
from table(flatten(input => parse_json('["prod", "staging", "dev", "cicd"]'))) f

union

select
    distinct
    f.value::string as unhashed_value,
    SHA2_HEX(f.value) AS hash_value
from table(flatten(input => parse_json('["apache", "singer-io", "transferwise", "meltano", "meltanolabs", "bytecodeio", "fishtown-analytics", "Mashey", "hotgluexyz", "Matatika", "Pathlight", "dbt-labs", "sqlfluff", "great-expectations", "dataops-tk", "anelendata", "AutoIDM", "datateer", "adswerve", "coeff", "shrutikaponde-vc", "datadotworld", "andyh1203", "prontopro", "estrategiahq", ""]'))) f
