-- Markdown tester tool https://app.slack.com/block-kit-builder/
WITH most_recent_date AS (

    {% if env_var("MELTANO_ENVIRONMENT") == "cicd" %}

        SELECT GREATEST(
                MAX(created_at_ts),
                MAX(pr_merged_at_ts),
                MAX(closed_at_ts)
            )::DATE AS max_date
        FROM {{ ref('singer_contributions') }}

    {% else %}

        SELECT CURRENT_DATE() AS max_date

    {% endif %}

),

base AS (
    SELECT
        ARRAY_AGG(
            CASE WHEN singer_contributions.contribution_type = 'pull_request'
                AND singer_contributions.state = 'open'
                AND singer_contributions.created_at_ts::DATE = DATEADD(
                    DAY, -1, most_recent_date.max_date
                )
                THEN {{ slack_message_generator() }}
            END
        ) AS prs_opened,
        ARRAY_AGG(
            CASE WHEN singer_contributions.contribution_type = 'pull_request'
                AND singer_contributions.state = 'closed'
                AND singer_contributions.pr_merged_at_ts::DATE = DATEADD(
                    DAY, -1, most_recent_date.max_date
                )
                THEN {{ slack_message_generator() }}
            END
        ) AS prs_merged,
        ARRAY_AGG(
            CASE WHEN singer_contributions.contribution_type = 'pull_request'
                AND singer_contributions.state = 'closed'
                AND singer_contributions.pr_merged_at_ts IS NULL
                AND singer_contributions.closed_at_ts::DATE = DATEADD(
                    DAY, -1, most_recent_date.max_date
                )
                THEN {{ slack_message_generator() }}
            END
        ) AS prs_closed,
        ARRAY_AGG(
            CASE WHEN singer_contributions.contribution_type = 'issue'
                AND singer_contributions.state = 'open'
                AND singer_contributions.created_at_ts::DATE = DATEADD(
                    DAY, -1, most_recent_date.max_date
                )
                THEN {{ slack_message_generator() }}
            END
        ) AS issues_opened,
        ARRAY_AGG(
            CASE WHEN singer_contributions.contribution_type = 'issue'
                AND singer_contributions.state = 'closed'
                AND singer_contributions.closed_at_ts::DATE = DATEADD(
                    DAY, -1, most_recent_date.max_date
                )
                THEN {{ slack_message_generator() }}
            END
        ) AS issues_closed
    FROM {{ ref('singer_contributions') }}
    CROSS JOIN most_recent_date
    LEFT JOIN {{ ref('stg_meltanohub__plugins') }}
        ON singer_contributions.repo_url = stg_meltanohub__plugins.repo
    WHERE singer_contributions.is_bot_user = FALSE
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
