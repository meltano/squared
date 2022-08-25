SELECT *
FROM {{ ref('snapshot_meltanohub_plugins') }}
WHERE dbt_valid_to IS NULL
