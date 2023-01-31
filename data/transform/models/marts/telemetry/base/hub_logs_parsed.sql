WITH base AS (
    SELECT
        log_message,
        created_at_ts,
        CASE
            WHEN
                startswith(
                    log_message, '('
                ) THEN substr(log_message, 40, 10000000)
            ELSE log_message
        END AS payload,
        CASE
            WHEN
                startswith(log_message, '(') THEN substr(log_message, 2, 36)
            ELSE parse_json(payload):requestId
        END AS request_id,
        CASE
            WHEN startswith(payload, 'Method') THEN split_part(payload, ':', 1)
        END AS method_type,
        CASE
            WHEN
                startswith(
                    payload, 'Method'
                ) THEN array_to_string(
                    array_slice(split(payload, ':'), 1, 100000000), ':'
                )
        END AS method_body,
        split_part(split_part(payload, 'User-Agent=', 2), ',', 1) AS user_agent,
        CASE
            WHEN method_type = 'Method completed with status' THEN method_body
        END AS status_code,
        CASE
            WHEN
                payload LIKE 'Received response.%' THEN split_part(
                    split_part(payload, 'Integration latency: ', 2), ' ms', 1
                )
        END AS integration_latency_ms,
        CASE
            WHEN
                user_agent LIKE 'Meltano%' THEN replace(
                    user_agent, 'Meltano/', ''
                )
        END AS meltano_version,
        split_part(
            split_part(payload, 'X-Meltano-Command=', 2), ',', 1
        ) AS command,
        split_part(
            split_part(payload, 'X-Project-ID=', 2), ', ', 1
        ) AS project_id,
        CASE
            WHEN startswith(payload, '{') THEN parse_json(payload):ip::string
        END AS ip_address,
        CASE
            WHEN
                startswith(
                    payload, 'HTTP Method: GET, Resource Path'
                ) THEN split_part(payload, ': ', 3)
        END AS request_path
    FROM {{ ref('stg_cloudwatch__log') }}
)

SELECT
    request_id,
    payload,
    method_type,
    method_body,
    user_agent,
    integration_latency_ms,
    status_code,
    request_path,
    meltano_version,
    command,
    project_id,
    log_message,
    created_at_ts,
    md5(ip_address) AS ip_address_hash
FROM base
