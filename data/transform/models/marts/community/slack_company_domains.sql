WITH company_domains AS (
    SELECT
        email_domain,
        COALESCE(
            message_created_at, CAST('1900-01-01' AS DATE)
        ) AS first_joined_date
    FROM {{ ref('slack_new_members') }}
    WHERE
        email_domain
        NOT IN (
            'gmail.com',
            'meltano.com',
            'yahoo.com',
            'googlemail.com',
            'hotmail.com',
            'msn.com',
            'outlook.com',
            ''
        )
),

company_domain_first_joined AS (
    SELECT
        email_domain,
        MIN(first_joined_date) AS first_join_date
    FROM company_domains GROUP BY 1 ORDER BY 1 DESC
)

SELECT * FROM company_domain_first_joined
WHERE first_join_date >= CAST('2021-09-01' AS DATE)
