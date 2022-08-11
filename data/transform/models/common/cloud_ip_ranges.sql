WITH ips AS (
    SELECT DISTINCT
        ip_address,
        'AWS' AS cloud_name,
        service,
        region,
        dbt_valid_from AS active_from,
        dbt_valid_to AS active_to
    FROM {{ ref('snapshot_ssa_aws_ips') }}

    UNION ALL

    SELECT DISTINCT
        ip_address,
        'AZURE' AS cloud_name,
        name AS service,
        NULL AS region,
        dbt_valid_from AS active_from,
        dbt_valid_to AS active_to
    FROM {{ ref('snapshot_ssa_azure_ips') }}

    UNION ALL

    SELECT DISTINCT
        COALESCE(ipv4, ipv6) AS ip_address,
        'GCP' AS cloud_name,
        service,
        scope AS region,
        dbt_valid_from AS active_from,
        dbt_valid_to AS active_to
    FROM {{ ref('snapshot_ssa_gcp_ips') }}

),

parsing AS (

    SELECT
        cloud_name,
        ip_address,
        service,
        region,
        PARSE_IP(ip_address, 'INET') AS obj,
        active_from,
        active_to
    FROM ips

)

SELECT
    cloud_name,
    ip_address,
    service,
    region,
    obj:ipv4_range_start::INT AS ipv4_range_start,
    obj:ipv4_range_end::INT AS ipv4_range_end,
    active_from,
    active_to
FROM parsing
