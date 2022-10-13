-- All contexts from contexts_base should arrive in one of the
-- parsed tables.
SELECT DISTINCT {{dbt_utils.surrogate_key(['event_id', 'schema_name'])}} FROM {{ ref('context_base') }}
MINUS
SELECT {{dbt_utils.surrogate_key(['event_id', 'schema_name'])}} FROM {{ ref('context_cli') }}
MINUS
SELECT {{dbt_utils.surrogate_key(['event_id', 'schema_name'])}} FROM {{ ref('context_environment') }}
MINUS
SELECT {{dbt_utils.surrogate_key(['event_id', 'schema_name'])}} FROM {{ ref('context_exception') }}
MINUS
SELECT {{dbt_utils.surrogate_key(['event_id', 'schema_name'])}} FROM {{ ref('context_plugins') }}
MINUS
SELECT {{dbt_utils.surrogate_key(['event_id', 'schema_name'])}} FROM {{ ref('context_project') }}
