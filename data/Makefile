run_meltano:
	meltano run tap-$(subst _,-,$(EXTRACT_SOURCE)) target-snowflake

install_extractor:
	meltano install extractor tap-$(subst _,-,$(EXTRACT_SOURCE))
