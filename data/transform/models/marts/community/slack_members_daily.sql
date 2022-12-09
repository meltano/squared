WITH new_member_message AS (

    SELECT
        message_created_at,
        SPLIT_PART(
            SPLIT_PART(message_content, '(<@', 2), '>)', 1
        ) AS parsed_user_id
    FROM {{ ref('stg_slack__messages') }}
    -- new-member-notice channel
    WHERE channel_id = 'C01SK13R9NJ'
        AND slack_username = 'New User Alert [bot]'

),

base AS (

    SELECT
        stg_slack__users.user_id,
        stg_slack__users.email_hash,
        stg_slack__users.email_domain,
        -- The slack bot was added on 2021-04-01. So we dont know the exact
        -- added date for user prior to that.
        COALESCE(
            new_member_message.message_created_at::DATE,
            '2021-04-01'::DATE
        ) AS added_date
    FROM {{ ref('stg_slack__users') }}
    LEFT JOIN
        new_member_message ON
            stg_slack__users.user_id = new_member_message.parsed_user_id
    WHERE NOT stg_slack__users.is_bot
        AND stg_slack__users.user_id != 'USLACKBOT'
        AND stg_slack__users.is_deleted = FALSE
),

daily AS (

    SELECT
        date_dim.date_day,
        COUNT(*) AS added
    FROM base
    LEFT JOIN {{ ref('date_dim') }}
        ON base.added_date = date_dim.date_day
    WHERE date_dim.date_day <= CURRENT_DATE
    GROUP BY 1
)

SELECT
    date_day,
    added,
    SUM(added) OVER (
        ORDER BY date_day ASC ROWS
        BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS total_members
FROM daily
