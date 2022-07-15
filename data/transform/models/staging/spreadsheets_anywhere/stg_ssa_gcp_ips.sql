WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                id
            ORDER BY _sdc_batched_at DESC
        ) AS row_num

    -- TODO: remove this once mappers are
    -- supported using jobs https://github.com/meltano/squared/issues/289
    {% if env_var("MELTANO_ENVIRONMENT") == "cicd" %}

        FROM raw.spreadsheets_anywhere.gcp_ips

    {% else %}

        FROM {{ source('tap_spreadsheets_anywhere', 'gcp_ips') }}

    {% endif %}

),

renamed AS (

    SELECT
        id,
        ipv4,
        ipv6,
        scope,
        service
    FROM source
    WHERE row_num = 1

)

SELECT
    *
FROM renamed
