

build-airflow:
	@echo 'building airflow image 🛠'
	docker build -t 158444585956.dkr.ecr.us-east-1.amazonaws.com/m5o-prod-airflow:latest -f Dockerfile.airflow ../../data
	@echo 'done ✅'

build-meltano:
	@echo 'building meltano image 🛠'
	docker build -t 158444585956.dkr.ecr.us-east-1.amazonaws.com/m5o-prod-meltano:latest -f Dockerfile.meltano ../../data

publish:
	@echo 'pushing meltano image 🚀'
	docker push 158444585956.dkr.ecr.us-east-1.amazonaws.com/m5o-prod-meltano:latest
	@echo 'pushing airflow image 🚀'
	docker push 158444585956.dkr.ecr.us-east-1.amazonaws.com/m5o-prod-airflow:latest
	@echo 'done ✅'
