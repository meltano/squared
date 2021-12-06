WITH parsed_all AS (

    SELECT DISTINCT COALESCE(company_name, email_domain) AS company_domain
    FROM {{ ref('stg_slack__users_all') }}

),

parsed_prior AS (

    SELECT DISTINCT COALESCE(company_name, email_domain) AS company_domain
    FROM {{ ref('stg_slack__users_prior') }}

),

diff AS (

    SELECT company_domain
    FROM parsed_all
    WHERE company_domain NOT IN (SELECT company_domain FROM parsed_prior)

)

SELECT * FROM diff
WHERE company_domain
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
