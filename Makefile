.PHONY: help setup venv-create venv-install infra-up infra-down \
       data-download data-subset data-upload ingest \
       docker-up docker-down docker-build \
       spark-local test-spark lint test clean

SHELL := /bin/bash
ENV ?= staging
VENV := dezcamp
PYTHON := $(VENV)/Scripts/python
PIP := $(VENV)/Scripts/pip
TERRAFORM_DIR := terraform

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

# ---------- Environment Setup ----------

setup: venv-create venv-install ## Full local setup: create venv + install deps
	@echo "Setup complete. Activate venv: $(VENV)\\Scripts\\activate"

venv-create: ## Create virtual environment
	python -m venv $(VENV)

venv-install: ## Install Python dependencies into venv
	$(PIP) install -r requirements.txt

# ---------- Infrastructure (Terraform) ----------

infra-up: ## Provision GCP resources (ENV=staging|prod)
	cd $(TERRAFORM_DIR) && terraform init && \
	terraform apply -var-file=envs/$(ENV).tfvars

infra-down: ## Tear down GCP resources (ENV=staging|prod)
	cd $(TERRAFORM_DIR) && terraform destroy -var-file=envs/$(ENV).tfvars

infra-plan: ## Preview infrastructure changes (ENV=staging|prod)
	cd $(TERRAFORM_DIR) && terraform init && \
	terraform plan -var-file=envs/$(ENV).tfvars

# ---------- Data Ingestion ----------

data-download: ## Download dataset from Kaggle
	$(PYTHON) scripts/download_from_kaggle.py

data-subset: ## Create 1-week dev subset from Oct 2019
	$(PYTHON) scripts/create_dev_subset.py

data-upload: ## Upload raw CSVs to GCS (ENV=staging|prod)
	$(PYTHON) scripts/upload_to_gcs.py

ingest: data-download data-subset ## Download data + create dev subset

# ---------- Airflow (Docker) ----------

docker-build: ## Build Airflow Docker image
	cd airflow && docker compose build

docker-up: ## Start Airflow locally (web UI at http://localhost:8080)
	cd airflow && docker compose up -d
	@echo "Airflow UI: http://localhost:8080  (admin / admin)"

docker-down: ## Stop Airflow containers
	cd airflow && docker compose down

docker-logs: ## Tail Airflow logs
	cd airflow && docker compose logs -f

# ---------- Spark ----------

spark-local: ## Run PySpark job locally on dev subset
	$(PYTHON) spark/jobs/process_events.py --env dev

# ---------- Testing ----------

test-spark: ## Run PySpark unit tests
	$(PYTHON) -m pytest spark/tests/ -v

lint: ## Run ruff linter
	$(PYTHON) -m ruff check .

test: lint test-spark ## Run all tests

# ---------- Cleanup ----------

clean: ## Remove local data and Docker volumes
	rm -rf data/raw/*.csv data/processed/*
	cd airflow && docker compose down -v
