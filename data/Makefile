hub_metrics_elt:
	meltano elt tap-google-analytics target-athena
	meltano invoke dbt:run
	meltano elt tap-athena-metrics target-yaml-metrics
	meltano elt tap-athena-audit target-yaml-audit

s3_upload:
	@echo "TODO: upload to s3"
