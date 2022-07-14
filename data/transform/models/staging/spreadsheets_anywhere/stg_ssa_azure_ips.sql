WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                id
            ORDER BY _sdc_batched_at DESC
        ) AS row_num
    FROM {{ source('tap_spreadsheets_anywhere', 'azure_ips') }}

),

renamed AS (

    SELECT
        id,
        name,
        _smart_source_file AS file_source,
        PARSE_JSON(
            REPLACE(properties, 'None', '""')
        ):addressPrefixes AS properties
    FROM source
    WHERE row_num = 1

),

flatten AS (
    SELECT
        renamed.id,
        renamed.name,
        renamed.file_source,
        addresses.value::STRING AS ip_address
    FROM renamed,
        LATERAL FLATTEN(
            input=>properties
        ) AS addresses

)

SELECT
    {{ dbt_utils.surrogate_key(
        ['id', 'ip_address']
    ) }} AS ip_surrogate_key,
    *
FROM flatten
