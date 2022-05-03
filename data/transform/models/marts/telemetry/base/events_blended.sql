WITH prep_snow AS (

	SELECT
        se_label AS project_id,
		event_created_at::date AS event_date,
		count(event_id) AS events
	FROM
		{{ ref('stg_snowplow__events') }}
 	GROUP BY 1,2
),

prep_ga AS (

	SELECT
        PROJECT_ID,
		event_date,
		sum(event_count) AS events
	FROM {{ ref('stg_ga__cli_events') }}
 	GROUP BY 1,2
)
,
projects_to_blend AS (
	
	SELECT
        prep_snow.project_id,
		min(prep_snow.event_date)::date AS snowplow_activate_date
	FROM prep_snow
	LEFT JOIN prep_ga ON prep_snow.project_id = prep_ga.project_id
		AND prep_snow.event_date = prep_ga.event_date
	WHERE COALESCE(100*(prep_snow.events*1.0/prep_ga.events), 100) >= 100
	GROUP BY 1
)
,
blended AS (
	SELECT
        'snowplow' AS event_source,
        1 AS event_count,
        a.se_category AS command_category,
        a.se_action AS command,
        a.se_label AS project_id,
        a.event_id,
        a.event_created_at
	FROM {{ ref('stg_snowplow__events') }} a
	INNER JOIN projects_to_blend b ON a.se_label = b.project_id
	WHERE a.event_created_at::date >= b.snowplow_activate_date
	
	UNION

	SELECT
        'ga',
        a.event_count,
        a.command_category,
        a.command,
        a.project_id,
        a.event_surrogate_key,
        a.event_date
	FROM {{ ref('stg_ga__cli_events') }} a
	LEFT JOIN projects_to_blend b ON a.project_id = b.project_id
	WHERE b.snowplow_activate_date IS NULL OR a.event_date::date < b.snowplow_activate_date
)
SELECT * FROM blended
