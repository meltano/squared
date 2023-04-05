WITH reparse_1 AS (
    -- Incident: new schema not registered to SnowcatCloud versions 2.14.0 and
    -- 2.15.0 (partial)
    -- Related issues: https://github.com/meltano/meltano/pull/7179 and
    -- https://github.com/meltano/meltano/pull/7256
    SELECT
        payload_enriched,
        uploaded_at
    FROM {{ ref('stg_snowplow__events_bad') }}
    WHERE
        uploaded_at::date BETWEEN '2023-01-17' AND '2023-02-02'
        AND failure_message[
            0
        ]:schemaKey::string
        = 'iglu:com.meltano/environment_context/jsonschema/1-2-0'

),

reparse_2 AS (
    -- Incident: exit_event incorrectly required not null exit_code
    -- Affected versions 2.0.3 - 2.6.0
    -- Related issues: https://github.com/meltano/meltano/issues/6243 and
    -- https://github.com/meltano/meltano/pull/6244
    SELECT
        payload_enriched,
        uploaded_at
    FROM {{ ref('stg_snowplow__events_bad') }}
    WHERE
        failure_message[
            0
        ]:schemaKey::string
        = 'iglu:com.meltano/exit_event/jsonschema/1-0-0'
        AND failure_message[
            0
        ]:error:dataReports[0]:message::string
        = '$.exit_code: null found, integer expected'

),

reparse_3 AS (
    -- Incident: events sent with schema name exceptions_context vs
    -- exception_context as registered in Snowcat
    -- Affected versions 2.0.1 - 2.0.2
    -- Related issues: https://github.com/meltano/meltano/issues/6213 and
    -- https://github.com/meltano/meltano/pull/6212
    SELECT
        uploaded_at,
        REPLACE(
            payload_enriched,
            'iglu:com.meltano/exceptions_context/jsonschema/1-0-0',
            'iglu:com.meltano/exception_context/jsonschema/1-0-0'
        ) AS payload_enriched
    FROM {{ ref('stg_snowplow__events_bad') }}
    WHERE
        failure_message[
            0
        ]:schemaKey::string
        = 'iglu:com.meltano/exceptions_context/jsonschema/1-0-0'

)

{% for cte_name in ['reparse_1', 'reparse_2', 'reparse_3'] %}

    {%- if not loop.first %}
        UNION ALL
    {% endif -%}

    SELECT -- noqa: L034
        PARSE_JSON(payload_enriched):app_id::string AS app_id,
        PARSE_JSON(payload_enriched):platform::string AS platform,
        PARSE_JSON(payload_enriched):etl_tstamp::string AS etl_tstamp,
        PARSE_JSON(
            payload_enriched
        ):collector_tstamp::string AS collector_tstamp,
        PARSE_JSON(
            payload_enriched
        ):dvce_created_tstamp::string AS dvce_created_tstamp,
        PARSE_JSON(payload_enriched):event::string AS event,
        PARSE_JSON(payload_enriched):event_id::string AS event_id,
        PARSE_JSON(payload_enriched):txn_id::string AS txn_id,
        PARSE_JSON(payload_enriched):name_tracker::string AS name_tracker,
        PARSE_JSON(payload_enriched):v_tracker::string AS v_tracker,
        PARSE_JSON(payload_enriched):v_collector::string AS v_collector,
        PARSE_JSON(payload_enriched):v_etl::string AS v_etl,
        PARSE_JSON(payload_enriched):user_id::string AS user_id,
        PARSE_JSON(payload_enriched):user_ipaddress::string AS user_ipaddress,
        PARSE_JSON(
            payload_enriched
        ):user_fingerprint::string AS user_fingerprint,
        PARSE_JSON(payload_enriched):domain_userid::string AS domain_userid,
        PARSE_JSON(
            payload_enriched
        ):domain_sessionidx::string AS domain_sessionidx,
        PARSE_JSON(payload_enriched):network_userid::string AS network_userid,
        PARSE_JSON(payload_enriched):geo_country::string AS geo_country,
        PARSE_JSON(payload_enriched):geo_region::string AS geo_region,
        PARSE_JSON(payload_enriched):geo_city::string AS geo_city,
        PARSE_JSON(payload_enriched):geo_zipcode::string AS geo_zipcode,
        PARSE_JSON(payload_enriched):geo_latitude::string AS geo_latitude,
        PARSE_JSON(payload_enriched):geo_longitude::string AS geo_longitude,
        PARSE_JSON(payload_enriched):geo_region_name::string AS geo_region_name,
        PARSE_JSON(payload_enriched):ip_isp::string AS ip_isp,
        PARSE_JSON(payload_enriched):ip_organization::string AS ip_organization,
        PARSE_JSON(payload_enriched):ip_domain::string AS ip_domain,
        PARSE_JSON(payload_enriched):ip_netspeed::string AS ip_netspeed,
        PARSE_JSON(payload_enriched):page_url::string AS page_url,
        PARSE_JSON(payload_enriched):page_title::string AS page_title,
        PARSE_JSON(payload_enriched):page_referrer::string AS page_referrer,
        PARSE_JSON(payload_enriched):page_urlscheme::string AS page_urlscheme,
        PARSE_JSON(payload_enriched):page_urlhost::string AS page_urlhost,
        PARSE_JSON(payload_enriched):page_urlport::string AS page_urlport,
        PARSE_JSON(payload_enriched):page_urlpath::string AS page_urlpath,
        PARSE_JSON(payload_enriched):page_urlquery::string AS page_urlquery,
        PARSE_JSON(
            payload_enriched
        ):page_urlfragment::string AS page_urlfragment,
        PARSE_JSON(payload_enriched):refr_urlscheme::string AS refr_urlscheme,
        PARSE_JSON(payload_enriched):refr_urlhost::string AS refr_urlhost,
        PARSE_JSON(payload_enriched):refr_urlport::string AS refr_urlport,
        PARSE_JSON(payload_enriched):refr_urlpath::string AS refr_urlpath,
        PARSE_JSON(payload_enriched):refr_urlquery::string AS refr_urlquery,
        PARSE_JSON(
            payload_enriched
        ):refr_urlfragment::string AS refr_urlfragment,
        PARSE_JSON(payload_enriched):refr_medium::string AS refr_medium,
        PARSE_JSON(payload_enriched):refr_source::string AS refr_source,
        PARSE_JSON(payload_enriched):refr_term::string AS refr_term,
        PARSE_JSON(payload_enriched):mkt_medium::string AS mkt_medium,
        PARSE_JSON(payload_enriched):mkt_source::string AS mkt_source,
        PARSE_JSON(payload_enriched):mkt_term::string AS mkt_term,
        PARSE_JSON(payload_enriched):mkt_content::string AS mkt_content,
        PARSE_JSON(payload_enriched):mkt_campaign::string AS mkt_campaign,
        PARSE_JSON(payload_enriched):contexts::string AS contexts,
        PARSE_JSON(payload_enriched):se_category::string AS se_category,
        PARSE_JSON(payload_enriched):se_action::string AS se_action,
        PARSE_JSON(payload_enriched):se_label::string AS se_label,
        PARSE_JSON(payload_enriched):se_property::string AS se_property,
        PARSE_JSON(payload_enriched):se_value::string AS se_value,
        PARSE_JSON(payload_enriched):unstruct_event::string AS unstruct_event,
        PARSE_JSON(payload_enriched):tr_orderid::string AS tr_orderid,
        PARSE_JSON(payload_enriched):tr_affiliation::string AS tr_affiliation,
        PARSE_JSON(payload_enriched):tr_total::string AS tr_total,
        PARSE_JSON(payload_enriched):tr_tax::string AS tr_tax,
        PARSE_JSON(payload_enriched):tr_shipping::string AS tr_shipping,
        PARSE_JSON(payload_enriched):tr_city::string AS tr_city,
        PARSE_JSON(payload_enriched):tr_state::string AS tr_state,
        PARSE_JSON(payload_enriched):tr_country::string AS tr_country,
        PARSE_JSON(payload_enriched):ti_orderid::string AS ti_orderid,
        PARSE_JSON(payload_enriched):ti_sku::string AS ti_sku,
        PARSE_JSON(payload_enriched):ti_name::string AS ti_name,
        PARSE_JSON(payload_enriched):ti_category::string AS ti_category,
        PARSE_JSON(payload_enriched):ti_price::string AS ti_price,
        PARSE_JSON(payload_enriched):ti_quantity::string AS ti_quantity,
        PARSE_JSON(payload_enriched):pp_xoffset_min::string AS pp_xoffset_min,
        PARSE_JSON(payload_enriched):pp_xoffset_max::string AS pp_xoffset_max,
        PARSE_JSON(payload_enriched):pp_yoffset_min::string AS pp_yoffset_min,
        PARSE_JSON(payload_enriched):pp_yoffset_max::string AS pp_yoffset_max,
        PARSE_JSON(payload_enriched):useragent::string AS useragent,
        PARSE_JSON(payload_enriched):br_name::string AS br_name,
        PARSE_JSON(payload_enriched):br_family::string AS br_family,
        PARSE_JSON(payload_enriched):br_version::string AS br_version,
        PARSE_JSON(payload_enriched):br_type::string AS br_type,
        PARSE_JSON(payload_enriched):br_renderengine::string AS br_renderengine,
        PARSE_JSON(payload_enriched):br_lang::string AS br_lang,
        PARSE_JSON(payload_enriched):br_features_pdf::string AS br_features_pdf,
        PARSE_JSON(
            payload_enriched
        ):br_features_flash::string AS br_features_flash,
        PARSE_JSON(
            payload_enriched
        ):br_features_java::string AS br_features_java,
        PARSE_JSON(
            payload_enriched
        ):br_features_director::string AS br_features_director,
        PARSE_JSON(
            payload_enriched
        ):br_features_quicktime::string AS br_features_quicktime,
        PARSE_JSON(
            payload_enriched
        ):br_features_realplayer::string AS br_features_realplayer,
        PARSE_JSON(
            payload_enriched
        ):br_features_windowsmedia::string AS br_features_windowsmedia,
        PARSE_JSON(
            payload_enriched
        ):br_features_gears::string AS br_features_gears,
        PARSE_JSON(
            payload_enriched
        ):br_features_silverlight::string AS br_features_silverlight,
        PARSE_JSON(payload_enriched):br_cookies::string AS br_cookies,
        PARSE_JSON(payload_enriched):br_colordepth::string AS br_colordepth,
        PARSE_JSON(payload_enriched):br_viewwidth::string AS br_viewwidth,
        PARSE_JSON(payload_enriched):br_viewheight::string AS br_viewheight,
        PARSE_JSON(payload_enriched):os_name::string AS os_name,
        PARSE_JSON(payload_enriched):os_family::string AS os_family,
        PARSE_JSON(payload_enriched):os_manufacturer::string AS os_manufacturer,
        PARSE_JSON(payload_enriched):os_timezone::string AS os_timezone,
        PARSE_JSON(payload_enriched):dvce_type::string AS dvce_type,
        PARSE_JSON(payload_enriched):dvce_ismobile::string AS dvce_ismobile,
        PARSE_JSON(
            payload_enriched
        ):dvce_screenwidth::string AS dvce_screenwidth,
        PARSE_JSON(
            payload_enriched
        ):dvce_screenheight::string AS dvce_screenheight,
        PARSE_JSON(payload_enriched):doc_charset::string AS doc_charset,
        PARSE_JSON(payload_enriched):doc_width::string AS doc_width,
        PARSE_JSON(payload_enriched):doc_height::string AS doc_height,
        PARSE_JSON(payload_enriched):tr_currency::string AS tr_currency,
        PARSE_JSON(payload_enriched):tr_total_base::string AS tr_total_base,
        PARSE_JSON(payload_enriched):tr_tax_base::string AS tr_tax_base,
        PARSE_JSON(
            payload_enriched
        ):tr_shipping_base::string AS tr_shipping_base,
        PARSE_JSON(payload_enriched):ti_currency::string AS ti_currency,
        PARSE_JSON(payload_enriched):ti_price_base::string AS ti_price_base,
        PARSE_JSON(payload_enriched):base_currency::string AS base_currency,
        PARSE_JSON(payload_enriched):geo_timezone::string AS geo_timezone,
        PARSE_JSON(payload_enriched):mkt_clickid::string AS mkt_clickid,
        PARSE_JSON(payload_enriched):mkt_network::string AS mkt_network,
        PARSE_JSON(payload_enriched):etl_tags::string AS etl_tags,
        PARSE_JSON(
            payload_enriched
        ):dvce_sent_tstamp::string AS dvce_sent_tstamp,
        PARSE_JSON(
            payload_enriched
        ):refr_domain_userid::string AS refr_domain_userid,
        PARSE_JSON(
            payload_enriched
        ):refr_dvce_tstamp::string AS refr_dvce_tstamp,
        PARSE_JSON(
            payload_enriched
        ):derived_contexts::string AS derived_contexts,
        PARSE_JSON(
            payload_enriched
        ):domain_sessionid::string AS domain_sessionid,
        collector_tstamp AS derived_tstamp,
        CASE
            WHEN unstruct_event IS NULL THEN 'com.google.analytics' ELSE
                SPLIT_PART(
                    SPLIT_PART(
                        PARSE_JSON(unstruct_event):data:schema::string, ':', 2
                    ),
                    '/',
                    1
                )
        END AS event_vendor,
        CASE
            WHEN unstruct_event IS NULL THEN 'event' ELSE
                SPLIT_PART(
                    SPLIT_PART(
                        PARSE_JSON(unstruct_event):data:schema::string, ':', 2
                    ),
                    '/',
                    2
                )
        END AS event_name,
        CASE
            WHEN unstruct_event IS NULL THEN 'jsonschema' ELSE
                SPLIT_PART(
                    SPLIT_PART(
                        PARSE_JSON(unstruct_event):data:schema::string, ':', 2
                    ),
                    '/',
                    3
                )
        END AS event_format,
        CASE
            WHEN unstruct_event IS NULL THEN '1-0-0' ELSE
                SPLIT_PART(
                    SPLIT_PART(
                        PARSE_JSON(unstruct_event):data:schema::string, ':', 2
                    ),
                    '/',
                    4
                )
        END AS event_version,
        PARSE_JSON(
            payload_enriched
        ):event_fingerprint::string AS event_fingerprint,
        PARSE_JSON(payload_enriched):true_tstamp::string AS true_tstamp,
        uploaded_at
    FROM {{ cte_name }}

{% endfor %}
