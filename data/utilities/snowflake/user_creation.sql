use role USERADMIN;

CREATE ROLE <INSERT_NAME> ;
GRANT ROLE <INSERT_NAME> TO ROLE "SYSADMIN";

CREATE USER <INSERT_NAME>
LOGIN_NAME = <INSERT_NAME>
DISPLAY_NAME = <INSERT_NAME>
FIRST_NAME = <INSERT_NAME>
LAST_NAME = <INSERT_NAME>
EMAIL = '<INSERT_NAME>@meltano.com'
DEFAULT_ROLE = <INSERT_NAME>
DEFAULT_WAREHOUSE = CORE
MUST_CHANGE_PASSWORD = TRUE;

GRANT ROLE <INSERT_NAME> to user <INSERT_NAME>;

ALTER USER <INSERT_NAME> RESET PASSWORD;
-- Share the reset URL returned by snowflake after creating the user.
-- They have 4 hrs to use the link before it expires.
-- Also shared this account URL for them to bookmark https://epa06486.snowflakecomputing.com/
