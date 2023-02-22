{{
    config(materialized='table')
}}

WITH unique_ips AS (
    SELECT DISTINCT
        user_ipaddress,
        ip_address_hash
    FROM {{ ref('stg_snowplow__events') }}
),

parsed AS (

    SELECT
        ip_address_hash,
        PARSE_IP(user_ipaddress, 'INET') AS obj
    FROM unique_ips

),

cloud_ips AS (

    SELECT
        parsed.ip_address_hash,
        cloud_ip_ranges.active_from,
        cloud_ip_ranges.active_to,
        MAX(cloud_ip_ranges.cloud_name) AS cloud_name,
        LISTAGG(
            DISTINCT cloud_ip_ranges.ip_address,
            ', '
        ) AS cloud_ip_addresses,
        LISTAGG(DISTINCT cloud_ip_ranges.service, ', ') AS cloud_services,
        LISTAGG(DISTINCT cloud_ip_ranges.region, ', ') AS cloud_regions
    FROM parsed, {{ ref('cloud_ip_ranges') }}
    WHERE parsed.obj:ipv4 BETWEEN cloud_ip_ranges.ipv4_range_start
        AND cloud_ip_ranges.ipv4_range_end
    GROUP BY 1, 2, 3

),

release_versions AS (

    SELECT
        unique_ips.ip_address_hash,
        LISTAGG(DISTINCT unstructured_executions.system_release, '') AS releases
    FROM unique_ips
    INNER JOIN {{ ref('unstructured_executions') }}
        ON unique_ips.ip_address_hash = unstructured_executions.ip_address_hash
    GROUP BY 1
),

base AS (

    SELECT
        cloud_ips.active_from,
        cloud_ips.active_to,
        unique_ips.ip_address_hash,
        CASE
            WHEN release_versions.releases LIKE '%amzn%' THEN 'AWS'
            WHEN release_versions.releases LIKE '%aws%' THEN 'AWS'
            WHEN release_versions.releases LIKE '%gcp%' THEN 'GCP'
            WHEN release_versions.releases LIKE '%azure%' THEN 'AZURE'
            ELSE 'NONE'
        END AS release_cloud_name,
        COALESCE(cloud_ips.cloud_name, 'NONE') AS cloud_provider
    FROM unique_ips
    LEFT JOIN cloud_ips
        ON unique_ips.ip_address_hash = cloud_ips.ip_address_hash
    LEFT JOIN release_versions
        ON unique_ips.ip_address_hash = release_versions.ip_address_hash

)

SELECT
    base.ip_address_hash,
    base.release_cloud_name,
    base.cloud_provider,
    CASE
        WHEN
            base.cloud_provider != 'NONE'
            OR base.release_cloud_name != 'NONE'
            THEN 'REMOTE'
        ELSE 'NOT_REMOTE'
    END AS execution_location,
    base.active_from,
    base.active_to,
    ip_org_mapping_lm.leadmagic_company_name AS org_name,
    ip_org_mapping_lm.leadmagic_company_domain AS org_domain
FROM base
LEFT JOIN {{ ref('ip_org_mapping_lm') }}
    ON base.ip_address_hash = ip_org_mapping_lm.ip_address_hash
LEFT JOIN {{ ref('meltano_cloud_ips') }}
    ON base.ip_address_hash = MD5(meltano_cloud_ips.ip_address)
WHERE meltano_cloud_ips.ip_address IS NULL

UNION ALL

SELECT
    MD5(ip_address) AS ip_address_hash,
    'UNKNOWN' AS release_cloud_name,
    'MELTANO_CLOUD' AS cloud_provider,
    'REMOTE' AS execution_location,
    '2022-11-16' AS active_from,
    NULL AS active_to,
    NULL AS org_name,
    NULL AS org_domain
FROM {{ ref('meltano_cloud_ips') }}

UNION ALL

SELECT
    'UNKNOWN' AS ip_address_hash,
    'UNKNOWN' AS release_cloud_name,
    'UNKNOWN' AS cloud_provider,
    'UNKNOWN' AS execution_location,
    NULL AS active_from,
    NULL AS active_to,
    NULL AS org_name,
    NULL AS org_domain
