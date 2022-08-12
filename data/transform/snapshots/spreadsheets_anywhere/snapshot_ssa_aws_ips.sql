{% snapshot snapshot_ssa_aws_ips %}

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
            ip_prefix AS ip_address,
            network_border_group,
            region,
            service
        FROM {{ source('tap_spreadsheets_anywhere', 'aws_ips') }}
        -- Handle hard deletes by only selecting most recent sync
        QUALIFY RANK() OVER (
                ORDER BY DATE_TRUNC('MINUTE', _sdc_batched_at) DESC
            ) = 1

    )

    SELECT *
    FROM source

{% endsnapshot %}
