{% snapshot snapshot_ssa_azure_ips %}

    {{
        config(
          target_schema=generate_schema_name('snapshot'),
          strategy='check',
          unique_key='ip_address',
          check_cols=['ip_address'],
          invalidate_hard_deletes=True
        )
    }}

    WITH source AS (

        SELECT
            id,
            name,
            _smart_source_file AS file_source,
            PARSE_JSON(
                REPLACE(properties, 'None', '""')
            ):addressPrefixes AS properties
        FROM {{ source('tap_spreadsheets_anywhere', 'azure_ips') }}
        -- Handle hard deletes by only selecting most recent sync
        QUALIFY RANK() OVER (
            ORDER BY date_trunc('MINUTE', _sdc_batched_at) DESC
        ) = 1

    ),

    flatten AS (
        SELECT
            source.id,
            source.name,
            source.file_source,
            addresses.value::STRING AS ip_address,
            ROW_NUMBER() OVER (
                PARTITION BY
                    addresses.value::STRING
                ORDER BY LEN(source.id) DESC
            ) AS row_num
        FROM source,
            LATERAL FLATTEN(
                input=>properties
            ) AS addresses

    )

    SELECT
        id,
        name,
        file_source,
        ip_address
    FROM flatten
    -- dedup and keep the longer service name description
    WHERE row_num = 1

{% endsnapshot %}