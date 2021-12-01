SELECT DISTINCT COALESCE(company_name, email_domain) AS company_name
FROM {{ ref('stg_slack__users') }}
WHERE company_name
    NOT IN (
        'gmail.com',
        'meltano.com',
        'yahoo.com',
        'googlemail.com',
        'hotmail.com',
        'msn.com'
    )
