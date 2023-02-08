WITH base AS (
    SELECT
        stg_snowplow__events.ip_address_hash,
        context_identify.leadmagic_company_name,
        context_identify.leadmagic_company_domain,
        ROW_NUMBER() OVER (
            PARTITION BY
                stg_snowplow__events.ip_address_hash
            ORDER BY stg_snowplow__events.event_created_at DESC
        ) AS row_num
    FROM {{ ref('stg_snowplow__events') }}
    LEFT JOIN {{ ref('context_identify') }}
        ON stg_snowplow__events.event_id = context_identify.event_id
    WHERE context_identify.leadmagic_company_name IS NOT NULL
)

SELECT DISTINCT
    ip_address_hash,
    leadmagic_company_name,
    leadmagic_company_domain
FROM base
-- TODO: think about using snapshots and active date range.
-- This simply choses the latest we know of.
WHERE row_num = 1
