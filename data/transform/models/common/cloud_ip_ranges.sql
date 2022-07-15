WITH ips AS (
    SELECT DISTINCT
        ip_address,
        'AWS' AS cloud_name,
        service,
        region
    FROM {{ ref('stg_ssa_aws_ips') }}

    UNION ALL

    SELECT DISTINCT
        ip_address,
        'AZURE' AS cloud_name,
        name AS service,
        NULL AS region
    FROM {{ ref('stg_ssa_azure_ips') }}

    UNION ALL

    SELECT DISTINCT
        COALESCE(ipv4, ipv6) AS ip_address,
        'GCP' AS cloud_name,
        service,
        scope AS region
    FROM {{ ref('stg_ssa_gcp_ips') }}

),

parsing AS (

    SELECT
        cloud_name,
        ip_address,
        service,
        region,
        PARSE_IP(ip_address, 'INET') AS obj
    FROM ips

)

SELECT
    cloud_name,
    ip_address,
    service,
    region,
    obj:ipv4_range_start::INT AS ipv4_range_start,
    obj:ipv4_range_end::INT AS ipv4_range_end
FROM parsing
