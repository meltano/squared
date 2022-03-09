USE ROLE accountadmin;

CREATE STORAGE INTEGRATION S3_SNOWCAT_INT
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = S3
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::158444585956:role/snowflake-read-role'
  STORAGE_ALLOWED_LOCATIONS = ('s3://mirror-sc-data-snowcat.meltano.com');

GRANT USAGE ON INTEGRATION S3_SNOWCAT_INT TO ROLE SYSADMIN;

-- Retrieve External ID for terraform module `deploy/infrastructure/snowflake.tf`
DESC INTEGRATION S3_SNOWCAT_INT;


USE ROLE SYSADMIN;
GRANT CREATE STAGE ON SCHEMA RAW.SNOWPLOW to SYSADMIN;

CREATE STAGE RAW.SNOWPLOW.SNOWCAT_S3_STAGE
  url = 's3://mirror-sc-data-snowcat.meltano.com/customer-data/meltano/enriched/stream/'
  storage_integration = S3_SNOWCAT_INT;


CREATE OR REPLACE FILE FORMAT RAW.SNOWPLOW.snowplow_tsv TYPE = CSV FIELD_DELIMITER = '\t';


CREATE OR REPLACE TABLE RAW.SNOWPLOW.EVENTS
(
    app_id                   VARCHAR,
    platform                 VARCHAR,
    etl_tstamp               VARCHAR,
    collector_tstamp         VARCHAR,
    dvce_created_tstamp      VARCHAR,
    event                    VARCHAR,
    event_id                 VARCHAR,
    txn_id                   VARCHAR,
    name_tracker             VARCHAR,
    v_tracker                VARCHAR,
    v_collector              VARCHAR,
    v_etl                    VARCHAR,
    user_id                  VARCHAR,
    user_ipaddress           VARCHAR,
    user_fingerprint         VARCHAR,
    domain_userid            VARCHAR,
    domain_sessionidx        VARCHAR,
    network_userid           VARCHAR,
    geo_country              VARCHAR,
    geo_region               VARCHAR,
    geo_city                 VARCHAR,
    geo_zipcode              VARCHAR,
    geo_latitude             VARCHAR,
    geo_longitude            VARCHAR,
    geo_region_name          VARCHAR,
    ip_isp                   VARCHAR,
    ip_organization          VARCHAR,
    ip_domain                VARCHAR,
    ip_netspeed              VARCHAR,
    page_url                 VARCHAR,
    page_title               VARCHAR,
    page_referrer            VARCHAR,
    page_urlscheme           VARCHAR,
    page_urlhost             VARCHAR,
    page_urlport             VARCHAR,
    page_urlpath             VARCHAR,
    page_urlquery            VARCHAR,
    page_urlfragment         VARCHAR,
    refr_urlscheme           VARCHAR,
    refr_urlhost             VARCHAR,
    refr_urlport             VARCHAR,
    refr_urlpath             VARCHAR,
    refr_urlquery            VARCHAR,
    refr_urlfragment         VARCHAR,
    refr_medium              VARCHAR,
    refr_source              VARCHAR,
    refr_term                VARCHAR,
    mkt_medium               VARCHAR,
    mkt_source               VARCHAR,
    mkt_term                 VARCHAR,
    mkt_content              VARCHAR,
    mkt_campaign             VARCHAR,
    contexts                 VARCHAR,
    se_category              VARCHAR,
    se_action                VARCHAR,
    se_label                 VARCHAR,
    se_property              VARCHAR,
    se_value                 VARCHAR,
    unstruct_event           VARCHAR,
    tr_orderid               VARCHAR,
    tr_affiliation           VARCHAR,
    tr_total                 VARCHAR,
    tr_tax                   VARCHAR,
    tr_shipping              VARCHAR,
    tr_city                  VARCHAR,
    tr_state                 VARCHAR,
    tr_country               VARCHAR,
    ti_orderid               VARCHAR,
    ti_sku                   VARCHAR,
    ti_name                  VARCHAR,
    ti_category              VARCHAR,
    ti_price                 VARCHAR,
    ti_quantity              VARCHAR,
    pp_xoffset_min           VARCHAR,
    pp_xoffset_max           VARCHAR,
    pp_yoffset_min           VARCHAR,
    pp_yoffset_max           VARCHAR,
    useragent                VARCHAR,
    br_name                  VARCHAR,
    br_family                VARCHAR,
    br_version               VARCHAR,
    br_type                  VARCHAR,
    br_renderengine          VARCHAR,
    br_lang                  VARCHAR,
    br_features_pdf          VARCHAR,
    br_features_flash        VARCHAR,
    br_features_java         VARCHAR,
    br_features_director     VARCHAR,
    br_features_quicktime    VARCHAR,
    br_features_realplayer   VARCHAR,
    br_features_windowsmedia VARCHAR,
    br_features_gears        VARCHAR,
    br_features_silverlight  VARCHAR,
    br_cookies               VARCHAR,
    br_colordepth            VARCHAR,
    br_viewwidth             VARCHAR,
    br_viewheight            VARCHAR,
    os_name                  VARCHAR,
    os_family                VARCHAR,
    os_manufacturer          VARCHAR,
    os_timezone              VARCHAR,
    dvce_type                VARCHAR,
    dvce_ismobile            VARCHAR,
    dvce_screenwidth         VARCHAR,
    dvce_screenheight        VARCHAR,
    doc_charset              VARCHAR,
    doc_width                VARCHAR,
    doc_height               VARCHAR,
    tr_currency              VARCHAR,
    tr_total_base            VARCHAR,
    tr_tax_base              VARCHAR,
    tr_shipping_base         VARCHAR,
    ti_currency              VARCHAR,
    ti_price_base            VARCHAR,
    base_currency            VARCHAR,
    geo_timezone             VARCHAR,
    mkt_clickid              VARCHAR,
    mkt_network              VARCHAR,
    etl_tags                 VARCHAR,
    dvce_sent_tstamp         VARCHAR,
    refr_domain_userid       VARCHAR,
    refr_dvce_tstamp         VARCHAR,
    derived_contexts         VARCHAR,
    domain_sessionid         VARCHAR,
    derived_tstamp           VARCHAR,
    event_vendor             VARCHAR,
    event_name               VARCHAR,
    event_format             VARCHAR,
    event_version            VARCHAR,
    event_fingerprint        VARCHAR,
    true_tstamp              VARCHAR,
    uploaded_at              TIMESTAMP_NTZ(9) DEFAULT CAST(CURRENT_TIMESTAMP() AS TIMESTAMP_NTZ(9))
);


CREATE OR REPLACE PIPE RAW.SNOWPLOW.EVENTS_PIPE auto_ingest= TRUE AS
COPY INTO RAW.SNOWPLOW.EVENTS
    FROM (SELECT $1, $2, $3, $4, $5, $6, $7, $8, $9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$40,$41,$42,$43,$44,$45,$46,$47,$48,$49,$50,$51,$52,$53,$54,$55,$56,$57,$58,$59,$60,$61,$62,$63,$64,$65,$66,$67,$68,$69,$70,$71,$72,$73,$74,$75,$76,$77,$78,$79,$80,$81,$82,$83,$84,$85,$86,$87,$88,$89,$90,$91,$92,$93,$94,$95,$96,$97,$98,$99,$100,$101,$102,$103,$104,$105,$106,$107,$108,$109,$110,$111,$112,$113,$114,$115,$116,$117,$118,$119,$120,$121,$122,$123,$124,$125,$126,$127,$128,$129,$130,$131,CAST(CURRENT_TIMESTAMP() AS TIMESTAMP_NTZ(9)) AS uploaded_at
          FROM @RAW.SNOWPLOW.SNOWCAT_S3_STAGE)
    FILE_FORMAT = (FORMAT_NAME = 'RAW.SNOWPLOW.snowplow_tsv')
    ON_ERROR = 'skip_file';
