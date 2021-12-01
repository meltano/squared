WITH parsed AS (

    SELECT DISTINCT COALESCE(company_name, email_domain) AS companies
    FROM {{ ref('stg_slack__users') }}

)

SELECT * FROM parsed
WHERE companies
    NOT IN (
        'gmail.com',
        'meltano.com',
        'yahoo.com',
        'googlemail.com',
        'hotmail.com',
        'msn.com'
    )
