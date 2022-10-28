WITH base AS (
    SELECT
        ARRAY_AGG(
            CASE WHEN contribution_type = 'pull_request'
                AND state = 'open'
                AND created_at_ts::date = DATEADD(DAY, -1, CURRENT_DATE())
                THEN {{ slack_message_generator() }}
            END
        ) AS prs_opened,
        ARRAY_AGG(
            CASE WHEN contribution_type = 'pull_request'
                AND state = 'closed'
                AND pr_merged_at_ts::date = DATEADD(DAY, -1, CURRENT_DATE())
                THEN {{ slack_message_generator() }}
            END
        ) AS prs_merged,
        ARRAY_AGG(
            CASE WHEN contribution_type = 'pull_request'
                AND state = 'closed'
                AND pr_merged_at_ts IS NULL
                AND closed_at_ts::date = DATEADD(DAY, -1, CURRENT_DATE())
                THEN {{ slack_message_generator() }}
            END
        ) AS prs_closed,
        ARRAY_AGG(
            CASE WHEN contribution_type = 'issue'
                AND state = 'open'
                AND created_at_ts::date = DATEADD(DAY, -1, CURRENT_DATE())
                THEN {{ slack_message_generator() }}
            END
        ) AS issues_opened,
        ARRAY_AGG(
            CASE WHEN contribution_type = 'issue'
                AND state = 'closed'
                AND closed_at_ts::date = DATEADD(DAY, -1, CURRENT_DATE())
                THEN {{ slack_message_generator() }}
            END
        ) AS issues_closed
    FROM {{ ref('singer_contributions') }}
    WHERE is_bot_user = FALSE
)

SELECT
    'Pull Requests' AS title,
    '*Opened* :heavy_plus_sign::' || ARRAY_TO_STRING(
        prs_opened, ''
    ) || '\n\n\n*Merged* :pr-merged:' || ARRAY_TO_STRING(
        prs_merged, ''
    ) || '\n\n\n*Closed* :wastebasket:' || ARRAY_TO_STRING(
        prs_closed, ''
    ) AS body
FROM base

UNION ALL

SELECT
    'Issues' AS title,
    '*Opened* :heavy_plus_sign::' || ARRAY_TO_STRING(
        issues_opened, ''
    ) || '\n\n\n*Closed* :wastebasket:' || ARRAY_TO_STRING(
        issues_closed, ''
    ) AS body
FROM base
