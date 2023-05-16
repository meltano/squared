{% snapshot snapshot_meltanohub_plugins %}

{{ config(
        target_schema=generate_schema_name('snapshot'),
        strategy='check',
        unique_key='id',
        check_cols='all',
        invalidate_hard_deletes=True
    ) }}

    WITH source AS (

        SELECT
            capabilities,
            commands,
            "DEFAULT" AS is_default, --noqa: L059
            description,
            dialect,
            docs,
            executable,
            hidden AS is_hidden,
            id,
            label,
            logo_url,
            metadata,
            name,
            namespace,
            pip_url,
            plugin_type,
            repo,
            requires,
            "SELECT" AS select_extra,
            settings,
            settings_group_validation,
            target_schema,
            "UPDATE" AS update_extra,
            variant
        FROM {{ source('tap_meltanohub', 'plugins') }}
        -- Handle hard deletes by only selecting most recent sync
        QUALIFY
            ROW_NUMBER() OVER (
                ORDER BY DATE_TRUNC('HOUR', _sdc_batched_at) DESC
            ) = 1
    )

    SELECT *
    FROM source

{% endsnapshot %}
