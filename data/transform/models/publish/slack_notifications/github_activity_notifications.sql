-- Markdown tester tool https://app.slack.com/block-kit-builder/
WITH most_recent_date AS (

    {% if env_var("MELTANO_ENVIRONMENT") == "cicd" %}

        SELECT
            GREATEST(
                MAX(created_at_ts),
                MAX(merged_at_ts),
                MAX(closed_at_ts)
            )::DATE AS max_date
        FROM {{ ref('contributions') }}

    {% else %}

        SELECT CURRENT_DATE() AS max_date

    {% endif %}

),

base AS (
    SELECT
        ARRAY_AGG(
            CASE
                WHEN
                    contributions.contribution_type = 'pull_request'
                    AND contributions.state = 'open'
                    AND contributions.created_at_ts::DATE >= DATEADD(
                        DAY, -1, most_recent_date.max_date
                    )
                    THEN {{ github_activity_slack_message_generator() }}
            END
        ) AS prs_opened,
        ARRAY_AGG(
            CASE
                WHEN
                    contributions.contribution_type = 'pull_request'
                    AND contributions.state = 'closed'
                    AND contributions.merged_at_ts::DATE >= DATEADD(
                        DAY, -1, most_recent_date.max_date
                    )
                    THEN {{ github_activity_slack_message_generator() }}
            END
        ) AS prs_merged,
        ARRAY_AGG(
            CASE
                WHEN
                    contributions.contribution_type = 'pull_request'
                    AND contributions.state = 'closed'
                    AND contributions.merged_at_ts IS NULL
                    AND contributions.closed_at_ts::DATE >= DATEADD(
                        DAY, -1, most_recent_date.max_date
                    )
                    THEN {{ github_activity_slack_message_generator() }}
            END
        ) AS prs_closed,
        ARRAY_AGG(
            CASE
                WHEN
                    contributions.contribution_type = 'issue'
                    AND contributions.state = 'open'
                    AND contributions.created_at_ts::DATE >= DATEADD(
                        DAY, -1, most_recent_date.max_date
                    )
                    THEN {{ github_activity_slack_message_generator() }}
            END
        ) AS issues_opened,
        ARRAY_AGG(
            CASE
                WHEN
                    contributions.contribution_type = 'issue'
                    AND contributions.state = 'closed'
                    AND contributions.closed_at_ts::DATE >= DATEADD(
                        DAY, -1, most_recent_date.max_date
                    )
                    THEN {{ github_activity_slack_message_generator() }}
            END
        ) AS issues_closed
    FROM {{ ref('contributions') }}
    CROSS JOIN most_recent_date
    WHERE contributions.is_team_contribution = FALSE
)

SELECT
    'Pull Requests' AS title,
    '*Opened* :heavy_plus_sign::' || ARRAY_TO_STRING(
        prs_opened, ''
    ) || '\n\n\n*Merged* :pr-merged::' || ARRAY_TO_STRING(
        prs_merged, ''
    ) || '\n\n\n*Closed* :wastebasket::' || ARRAY_TO_STRING(
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
