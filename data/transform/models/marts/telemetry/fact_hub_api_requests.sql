WITH base AS (

    SELECT
        request_id,
        MAX(project_id) AS project_id,
        MAX(command) AS command,
        MAX(ip_address_hash) AS ip_address_hash,
        MAX(integration_latency_ms) AS integration_latency_ms,
        MAX(status_code) AS status_code,
        MAX(request_path) AS request_path,
        MAX(meltano_version) AS meltano_version,
        MIN(created_at_ts) AS log_start_ts,
        MAX(created_at_ts) AS log_end_ts
    FROM {{ ref('hub_logs_parsed') }}
    GROUP BY 1
)

SELECT
    base.*,
    date_dim.date_day AS date_day
FROM base
LEFT JOIN {{ ref('date_dim') }}
    ON base.log_start_ts::date = date_dim.date_day
