{{
    config(
        materialized='incremental',
        unique_key='ts_datetime'
    )
}}

{% set tap_names = ['3plcentral', 'abcfinancial', 'aconex', 'activecampaign', 'acuite', 'adroll', 'adyen', 'agilecrm', 'urban', 'airtable', 'amazon', 'amazon', 'amazon', 'anaplan', 'kafka', 'apparel', 'appfigures', 'appstore', 'appsflyer', 'asana', 'ask', 'athena', 'auth0', 'autodesk', 'autopilot', 'awin', 'aws', 's3', 'basecone', 'hellobaton', 'bazaarvoice', 'bigcommerce', 'bigquery', 'billwerk', 'bing', 'bling', 'bold', 'braintree', 'brightpearl', 'bronto', 'bls', 'bynder', 'call', 'campaign', 'carbon', 'centra', 'chargebee', 'chargify', 'chatitive', 'circle', 'clarabridge', 'clickup', 'clockify', 'closeio', 'clover', 'clubhouse', 'clubspeed', 'codat', 'confluence', 'contentful', 'coosto', 'criteo', 'crossbeam', 'csv', 'currencyfreaks', 'customerx', 'daisycon', 'dayforce', 'dbt', 'dbt', 'density', 'deputy', 'domo', 'dynamics', 'dynamodb', 'ebay', 'eloqua', 'emarsys', 'estoca', 'eventbrite', 'exactsales', 'exchangeratehost', 'exchangeratesapi', 'fabdb', 'facebook', 'facebook', 'facebook', 'facebook', 'fastly', 'feed', 'five9', 'fixerio', 'forecast', 'freshdesk', 'frontapp', 'fulfil', 'fullstory', 'purecloud', 'github', 'gitlab', 'gleantap', 'gmail', 'adwords', 'googleads', 'google', 'search', 'google', 'gorgias', 'greenhouse', 'harvest', 'helpscout', 'helpshift', 'holidays', 'hubplanner', 'hubspot', 'db2', 'idealo', 'ilevel', 'immuta', 'impact', 'indeed', 'insided', 'insightly', 'instagram', 'intercom', 'invoiced', 'ireckonu', 'iterable', 'jira', 'kanbanize', 'klaviyo', 'kustomer', 'kwanko', 'lever', 'linkedin', 'listen360', 'listrak', 'livechat', 'liveperson', 'grader', 'logmeinrescue', 'looker', 'lookml', 'loopreturns', 'maestroqa', 'mailchimp', 'mailgun', 'mailshake', 'mambu', 'marketman', 'marketo', 'mavenlink', 'megaphone', 'meltano', 'mercadopago', 'mssql', 'ms', 'mixpanel', 'mode', 'monday', 'mongodb', 'mysql', 'netlify', 'netsuite', 'newrelic', 'nikabot', 'officernd', 'okta', 'onfleet', 'open', 'openweathermap', 'oracle', 'orbit', 'ordway', 'outbrain', 'outreach', 'pagerduty', 'pardot', 'parquet', 'paypal', 'peloton', 'pendo', 'pepperjam', 'persistiq', 'pinterest', 'pipedrive', 'pivotal', 'platformpurple', 'pubg', 'postgres', 'postmark', 'powerbi', 'process', 'procore', 'prometheus', 'quaderno', 'quickbase', 'quickbooks', 'rakuten', 'readthedocs', 'recharge', 'recruitee', 'recurly', 'redash', 'redshift', 'referral', 'responsys', 'rest', 'reviewscouk', 'revinate', 'richpanel', 'rickandmorty', 'ringcentral', 'rockgympro', 'saasoptics', 'intacct', 'sailthru', 'salesforce', 'exacttarget', 'webcrawl', 'selligent', 'sendgrid', 'sendinblue', 'sentry', 'servicem8', 'sevenrooms', 'sftp', 'shiphero', 'shipstation', 'shopify', 'signonsite', 'simplifi', 'sklik', 'skubana', 'slack', 'sleeper', 'sling', 'smartsheet', 'sms', 'snapchat', 'snapengage', 'snowflake', 'solarvista', 'spotify', 'spreadsheets', 'square', 'stackexchange', 'starshipit', 'stella', 'strava', 'stringee', 'stripe', 'sumologic', 'surveymonkey', 'taboola', 'talkable', 'teamwork', 'telemetrics', 'lotr', 'thunderboard', 'tickettailor', 'tiktok', 'timebutler', 'toast', 'toggl', 'treez', 'trello', 'trustpilot', 'twilio', 'twinfield', 'twitter', 'typeform', 'typo', 'udemy', 'ujet', 'uncategorized', 'uservoice', 'vnda', 'walkscore', 'webcrm', 'wonolo', 'woocommerce', 'wootric', 'wordpress', 'workday', 'workramp', 'xero', 'yotpo', 'youtube', 'zendesk', 'zenefits', 'tap', 'zoom', 'zuora'] %}

SELECT DISTINCT
    channel_id,
    channel_name,
    message,
    ts_datetime, 
    thread_datetime,
    is_tap_message,
    CASE
    {% for tap_name in tap_names %}
        WHEN REGEXP_LIKE(message, '.*[Tt]ap.*{{ tap_name }}.*') THEN '{{ tap_name }}'
        WHEN REGEXP_LIKE(message, '.*{{ tap_name }}.*[Tt]ap.*') THEN '{{ tap_name }}' 
    {% endfor %}
        ELSE "general_tap"
    END AS tap_id
FROM categorized_messages
WHERE is_tap_message = True
ORDER BY thread_datetime, ts_datetime