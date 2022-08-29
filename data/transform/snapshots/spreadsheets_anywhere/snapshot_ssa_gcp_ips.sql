{% snapshot snapshot_ssa_gcp_ips %}

    {{
        config(
          target_schema=generate_schema_name('snapshot'),
          strategy='check',
          unique_key='id',
          check_cols=['id'],
          invalidate_hard_deletes=True
        )
    }}

    WITH source AS (

        SELECT
            id,
            ipv4,
            ipv6,
            scope,
            service
        FROM {{ source('tap_spreadsheets_anywhere', 'gcp_ips') }}
        -- Handle hard deletes by only selecting most recent sync
        QUALIFY RANK() OVER (
                ORDER BY DATE_TRUNC('MINUTE', _sdc_batched_at) DESC
            ) = 1

    )

    SELECT *
    FROM source

{% endsnapshot %}
