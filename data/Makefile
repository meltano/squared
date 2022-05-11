run_meltano:
	meltano --log-level=debug run tap-$(subst _,-,$(EXTRACT_SOURCE)) target-snowflake

install_extractor:
	meltano install extractor tap-$(subst _,-,$(EXTRACT_SOURCE))
