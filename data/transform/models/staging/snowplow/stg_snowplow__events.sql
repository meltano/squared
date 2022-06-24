{{
    config(
        materialized='incremental'
    )
}}

WITH source AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                event_id
            ORDER BY derived_tstamp::TIMESTAMP DESC
        ) AS row_num

        {% if env_var("MELTANO_ENVIRONMENT") == "cicd" %}

        FROM raw.snowplow.events
        WHERE derived_tstamp::TIMESTAMP >= DATEADD('day', -7, CURRENT_DATE)
            -- filter test events
            AND app_id != 'test'
        {% else %}

        FROM {{ source('snowplow', 'events') }}

            {% if is_incremental() %}

            WHERE UPLOADED_AT >= (SELECT max(UPLOADED_AT) FROM {{ this }})

            {% endif %}

        {% endif %}



),

clean_new_source AS (

    SELECT
        *
    FROM source
    WHERE row_num = 1
    {% if is_incremental() %}

        AND event_id NOT IN (
            SELECT DISTINCT event_id FROM {{ this }}
        )
    {% endif %}

),

renamed AS (

    SELECT
        app_id,
        platform,
        etl_tstamp::TIMESTAMP AS etl_enriched_at,
        collector_tstamp::TIMESTAMP AS collector_received_at,
        dvce_created_tstamp::TIMESTAMP AS device_created_at,
        dvce_sent_tstamp::TIMESTAMP AS device_sent_at,
        refr_dvce_tstamp::TIMESTAMP AS refr_device_processed_at,
        derived_tstamp::TIMESTAMP AS event_created_at,
        derived_tstamp::DATE AS event_created_date,
        true_tstamp::TIMESTAMP AS true_sent_at,
        uploaded_at,
        event,
        event_id,
        txn_id,
        name_tracker,
        v_tracker,
        v_collector,
        v_etl,
        user_id,
        user_ipaddress,
        user_fingerprint,
        domain_userid,
        domain_sessionidx,
        network_userid,
        geo_country,
        geo_region,
        geo_city,
        geo_zipcode,
        geo_latitude,
        geo_longitude,
        geo_region_name,
        ip_isp,
        ip_organization,
        ip_domain,
        ip_netspeed,
        page_url,
        page_title,
        page_referrer,
        page_urlscheme,
        page_urlhost,
        page_urlport,
        page_urlpath,
        page_urlquery,
        page_urlfragment,
        refr_urlscheme,
        refr_urlhost,
        refr_urlport,
        refr_urlpath,
        refr_urlquery,
        refr_urlfragment,
        refr_medium,
        refr_source,
        refr_term,
        mkt_medium,
        mkt_source,
        mkt_term,
        mkt_content,
        mkt_campaign,
        contexts,
        se_category,
        se_action,
        se_label,
        se_property,
        se_value,
        unstruct_event,
        tr_orderid,
        tr_affiliation,
        tr_total,
        tr_tax,
        tr_shipping,
        tr_city,
        tr_state,
        tr_country,
        ti_orderid,
        ti_sku,
        ti_name,
        ti_category,
        ti_price,
        ti_quantity,
        pp_xoffset_min,
        pp_xoffset_max,
        pp_yoffset_min,
        pp_yoffset_max,
        useragent,
        br_name,
        br_family,
        br_version,
        br_type,
        br_renderengine,
        br_lang,
        br_features_pdf,
        br_features_flash,
        br_features_java,
        br_features_director,
        br_features_quicktime,
        br_features_realplayer,
        br_features_windowsmedia,
        br_features_gears,
        br_features_silverlight,
        br_cookies,
        br_colordepth,
        br_viewwidth,
        br_viewheight,
        os_name,
        os_family,
        os_manufacturer,
        os_timezone,
        dvce_type,
        dvce_ismobile,
        dvce_screenwidth,
        dvce_screenheight,
        doc_charset,
        doc_width,
        doc_height,
        tr_currency,
        tr_total_base,
        tr_tax_base,
        tr_shipping_base,
        ti_currency,
        ti_price_base,
        base_currency,
        geo_timezone,
        mkt_clickid,
        mkt_network,
        etl_tags,
        refr_domain_userid,
        derived_contexts::VARIANT AS derived_contexts,
        domain_sessionid,
        event_vendor,
        event_name,
        event_format,
        event_version,
        event_fingerprint
    FROM clean_new_source

)

SELECT
    *
FROM renamed
