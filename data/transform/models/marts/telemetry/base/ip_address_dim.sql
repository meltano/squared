WITH unique_ips AS (
    SELECT DISTINCT user_ipaddress
    FROM {{ ref('stg_snowplow__events') }}
),

parsed AS (

    SELECT
        user_ipaddress,
        PARSE_IP(user_ipaddress, 'INET') AS obj
    FROM unique_ips

),

cloud_ips AS (

    SELECT
        parsed.user_ipaddress,
        MAX(cloud_ip_ranges.cloud_name) AS cloud_name,
        LISTAGG(cloud_ip_ranges.ip_address, ', ') AS cloud_ip_addresses,
        LISTAGG(cloud_ip_ranges.service, ', ') AS cloud_services,
        LISTAGG(cloud_ip_ranges.region, ', ') AS cloud_regions
    FROM parsed, {{ ref('cloud_ip_ranges') }}
    WHERE parsed.obj:ipv4 BETWEEN cloud_ip_ranges.ipv4_range_start
        AND cloud_ip_ranges.ipv4_range_end
    GROUP BY 1

),

release_versions AS (

    SELECT
        unique_ips.user_ipaddress,
        LISTAGG(unstructured_executions.system_release, '') AS releases
    FROM unique_ips
    INNER JOIN {{ ref('unstructured_executions') }}
        ON unique_ips.user_ipaddress = unstructured_executions.user_ipaddress
    GROUP BY 1
),

base AS (

    SELECT
        MD5(unique_ips.user_ipaddress) AS ip_address_hash,
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
        ON unique_ips.user_ipaddress = cloud_ips.user_ipaddress
    LEFT JOIN release_versions
        ON unique_ips.user_ipaddress = release_versions.user_ipaddress

)

SELECT
    ip_address_hash,
    release_cloud_name,
    cloud_provider,
    CASE
        WHEN
            cloud_provider != 'NONE'
            OR release_cloud_name != 'NONE'
            THEN 'REMOTE'
        ELSE 'NOT_REMOTE'
    END AS execution_location
FROM base

UNION ALL

SELECT
    'UNKNOWN' AS ip_address_hash,
    'UNKNOWN' AS release_cloud_name,
    'UNKNOWN' AS cloud_provider,
    'UNKNOWN' AS execution_location
