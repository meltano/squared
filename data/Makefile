SHELL := /bin/bash

hub_metrics_elt:
	meltano elt tap-google-analytics target-athena
	meltano invoke dbt:run
	meltano elt tap-athena-metrics target-yaml-metrics
	meltano elt tap-athena-audit target-yaml-audit

s3_upload:
	meltano invoke awscli s3 cp audit.yml s3://${S3_BUCKET}/hub_metrics/
	meltano invoke awscli s3 cp metrics.yml s3://${S3_BUCKET}/hub_metrics/

lint:
	meltano invoke sqlfluff lint -v
