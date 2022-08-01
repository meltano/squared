WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                id
            ORDER BY _sdc_batched_at DESC
        ) AS row_num
    FROM {{ source('tap_meltanohub', 'plugins') }}

),

renamed AS (

    SELECT
        _sdc_batched_at AS updated_at,
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
    FROM source
    WHERE row_num = 1

)

SELECT *
FROM renamed
