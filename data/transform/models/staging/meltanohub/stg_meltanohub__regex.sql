WITH source AS (
    
    SELECT
        name :: text AS plugin_name,
            --Ex: slack
        executable :: text AS additional_regex,
            --Ex: tap-slack
        plugin_type :: text AS plugin_category,
            --Ex: tap or extractor???
        CASE WHEN additional_regex IS NOT null
            THEN plugin_name || '|' || additional_regex
            ELSE plugin_name
        END AS plugin_regex
    FROM {{ ref('stg_meltanohub__plugins') }}
        --This sets up the regex expressions that will be used per plugin per message
        --Sample: tap-slack

)

SELECT * FROM source 