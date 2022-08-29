{%- set query_results = dbt_utils.get_query_results_as_dict('SELECT plugin_name, plugin_regex, plugin_category FROM ' ~ ref('stg_meltanohub__regex')) -%}

WITH messages AS (

    SELECT
        *
    FROM {{ ref('stg_slack__threads') }}

),

sentences AS (

    SELECT
        *,
        split(regexp_replace(regexp_replace(message_content, '\\n\\n', ' '), '[!.?)] ', 'xxx'), 'xxx') AS sentence_text_list,
    FROM messages

),

flatten AS (

    SELECT 
        message_surrogate_key AS message_id,
        channel_id,
        message_created_at,
        thread_ts,
        user_id,
        s.value::text as sentence_text,
    FROM sentences,
        lateral flatten(input => sentext_text_list) AS s

)

SELECT * FROM flatten
