

build:
	@echo 'building meltano image 🛠'
	docker build -t 158444585956.dkr.ecr.us-east-1.amazonaws.com/m5o-prod-meltano:latest -f data/meltano/Dockerfile ../../data
	@echo 'building airflow image 🛠'
	docker build -t 158444585956.dkr.ecr.us-east-1.amazonaws.com/m5o-prod-airflow:latest -f data/airflow/Dockerfile ../../data
	@echo 'done ✅'

publish:
	@echo 'pushing meltano image 🚀'
	docker push 158444585956.dkr.ecr.us-east-1.amazonaws.com/m5o-prod-meltano:latest
	@echo 'pushing airflow image 🚀'
	docker push 158444585956.dkr.ecr.us-east-1.amazonaws.com/m5o-prod-airflow:latest
	@echo 'done ✅'
