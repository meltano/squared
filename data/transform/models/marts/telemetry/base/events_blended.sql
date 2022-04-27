-- prefer snowplow
-- if snowplow events and ga events exist for project id, find first date where the overlap happened, add a day for potential partial days where meltano was upgraded midday so we default to GA until were sure we have the full day,

WITH prep AS (

	SELECT
        a.se_label AS project_id,
        min(a.event_created_at) AS first_snowplow_ts
        -- ,
        -- max(a.event_created_at) AS latest_snowplow_ts,
        -- max(b.event_date) AS latest_ga_date,
	FROM
		{{ ref('stg_snowplow__events') }} a
	LEFT JOIN {{ ref('stg_ga__cli_events') }} b ON
		b.PROJECT_ID = a.se_label
	-- WHERE b.PROJECT_ID = '4929f81d-decd-401c-87b8-d8eba1e0902f'
	GROUP BY 1

)
,
projects_to_blend AS (

	SELECT
		project_id,
		-- first_snowplow_ts,
		DATEADD(DAY, 2, first_snowplow_ts::date) AS snowplow_activate_date
        -- ,
		-- DATEDIFF(DAY, first_snowplow_ts, current_timestamp) AS days_snowplow_active,
		-- latest_snowplow_ts,
		-- DATEDIFF(DAY, latest_snowplow_ts, current_timestamp) AS days_since_snowplow_latest_event,
		-- latest_ga_date,
		-- DATEDIFF(DAY, latest_ga_date, current_timestamp) AS days_since_ga_latest_event
	FROM prep WHERE first_snowplow_ts IS NOT NULL
	and DATEDIFF(DAY, first_snowplow_ts, current_timestamp) > 1
--	overlap plus buffer
-- majority of events are snowplow after buffer, local upgrade but not prod
--	ga not deactivate on their version
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
	
	UNION ALL

	SELECT
        'ga',
        a.event_count,
        a.command_category,
        a.command,
        a.project_id,
        a.event_surrogate_key,
        a.event_date
	FROM {{ ref('stg_ga__cli_events') }} a
	INNER JOIN projects_to_blend b ON a.project_id = b.project_id
	WHERE a.event_date::date < b.snowplow_activate_date
)
,
other AS (

	SELECT
        'ga' AS event_source,
        event_count,
        command_category,
        command,
        project_id,
        event_surrogate_key,
        event_date
	FROM {{ ref('stg_ga__cli_events') }}
	WHERE project_id NOT IN (
        SELECT DISTINCT project_id FROM projects_to_blend
    )
)
SELECT * FROM blended
UNION ALL
SELECT * FROM other