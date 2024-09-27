WITH interactive_config AS (
    SELECT
        'INTERACTIVE_CONFIG' AS feature_id,
        execution_id
    FROM {{ ref('cli_executions_base') }}
    WHERE
        cli_command = 'config'
        AND GET(COALESCE(GET(options_obj, 'set'), { }), 'interactive') = TRUE
),

elt_state AS (
    SELECT
        'ELT_STATE_ARG' AS feature_id,
        execution_id
    FROM {{ ref('cli_executions_base') }}
    WHERE
        cli_command = 'elt'
        AND NULLIF(
            -- WARNING: this is likely not accurate anymore 
            TRIM(GET(COALESCE(GET(options_obj, 'elt'), { }), 'state')), 'null'
        ) IS NOT NULL

),

plugin_inherits_from AS (
    SELECT DISTINCT
        'PLUGIN_INHERITS_FROM' AS feature_id,
        execution_id
    FROM {{ ref('fact_plugin_usage') }}
    WHERE
        parent_name != 'UNKNOWN'
        AND parent_name != plugin_name
),

mappers AS (
    SELECT DISTINCT
        'MAPPERS' AS feature_id,
        execution_id
    FROM {{ ref('fact_plugin_usage') }}
    WHERE plugin_type = 'mappers'
),

environments AS (
    SELECT
        'ENVIRONMENTS' AS feature_id,
        execution_id
    FROM {{ ref('cli_executions_base') }}
    WHERE environment_name_hash IS NOT NULL
),

test AS (
    SELECT
        'TEST' AS feature_id,
        execution_id
    FROM {{ ref('fact_cli_executions') }}
    WHERE cli_command = 'test'
),

run AS (
    SELECT
        'RUN' AS feature_id,
        execution_id
    FROM {{ ref('fact_cli_executions') }}
    WHERE cli_command = 'run'
)

{{ feature_usage_macro(
    [
        'interactive_config',
        'elt_state',
        'plugin_inherits_from',
        'mappers',
        'environments',
        'test',
        'run'
    ]
) }}
