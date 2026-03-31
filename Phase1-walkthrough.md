# Phase 1 Walkthrough (Beginner Friendly)

This guide is for users with no prior cloud or Terraform experience. Follow it in order. Each step includes a verification check so you can confirm it is done correctly.

## Goal Of Phase 1

Set up a working local + cloud-ready foundation for the project:
- Python environment (`dezcamp`)
- Local tooling (Docker, Terraform, gcloud)
- GCP project and service account
- Environment configuration (`.env`)
- Terraform dry-run and apply for staging
- Data download + 1-week subset creation
- Airflow local startup

If all checks pass, Phase 1 is complete.

## Before You Start

You need:
- Windows 10/11
- Git
- Python 3.10+ (you have 3.13)
- Docker Desktop (already installed)
- A Google account
- A Kaggle account

Recommended: run commands in PowerShell from project root:

```powershell
cd d:\Repos\DataEngineeringZoomcamp2026\shopper-behavior-pipeline
```

---

## Step 1: Verify Repo/Branch State

### Action

```powershell
git branch
git status
```

### Verify
- Current branch should be `feature/phase-1-infra`
- Working tree should be clean (or only expected local config edits)

---

## Step 2: Create And Activate Virtual Environment

### Action

```powershell
python -m venv dezcamp
.\dezcamp\Scripts\activate
pip install -r requirements.txt
```

### Verify

```powershell
python --version
pip --version
python -c "import pyspark, dbt.version, pytest; print(pyspark.__version__, dbt.version.__version__, pytest.__version__)"
```

Expected:
- Commands run from `dezcamp` environment
- No import errors

---

## Step 3: Install Terraform

### Action
1. Download Terraform (Windows AMD64) from [HashiCorp Downloads](https://developer.hashicorp.com/terraform/downloads)
2. Extract `terraform.exe`
3. Place it in a folder in your `PATH` (for example `C:\tools\terraform\`)
4. Reopen PowerShell

Add that folder to your PATH (this is the part people often miss)

Go to:
System Properties → Environment Variables → Path
Add:
C:\tools\terraform

⚠️ Just placing the file is NOT enough — it must be in PATH.

Reopen PowerShell - required for PATH refresh

### Verify

```powershell
terraform --version
```

Expected: version output (for example `Terraform v1.x.x`)

In PowerShell, run:

```powershell
where terraform
```

If this returns a path → you’re set
If not → PATH issue

---

## Step 4: Install Google Cloud CLI (`gcloud`)

### Action
1. Install from [Google Cloud CLI docs](https://cloud.google.com/sdk/docs/install)
2. Reopen PowerShell
3. Login:

```powershell
gcloud auth login
gcloud config set project YOUR_GCP_PROJECT_ID
```

### Verify

```powershell
gcloud --version
gcloud config list
```

Add this (very important). This confirms you're actually logged in.:
```powershell
gcloud auth list
```


Expected:
- `gcloud` command works
- Current project is your intended project


On Windows, prefer the official installer (.exe)
It automatically:
Adds gcloud to PATH
Installs Python if needed

---

## Step 5: Create GCP Project (If Needed)

If you do not already have a project:

### Action
1. Go to [GCP Console](https://console.cloud.google.com/)
2. Create a project (example: `shopper-behavior-pipeline`)
3. Enable billing
4. Enable APIs:
   - Compute Engine API
   - Cloud Dataproc API
   - BigQuery API
   - Cloud Storage API

### Verify

Quick check
```powershell
gcloud beta billing projects describe YOUR_PROJECT_ID
```

- In GCP Console, project is selected
- APIs show as enabled in `APIs & Services`

Enable APIs
```powershell
gcloud services enable compute.googleapis.com
gcloud services enable dataproc.googleapis.com
gcloud services enable bigquery.googleapis.com
gcloud services enable storage.googleapis.com
```

Verify
```powershell
gcloud services list --enabled
```

---

Some checks:
```powershell
gcloud config get-value project

```

gcloud config get-value project

## Step 6: Create Service Account Key

### Action
1. In GCP Console: `IAM & Admin` -> `Service Accounts`
2. Create service account (example: `pipeline-sa`)
3. Grant roles:
   - `Storage Admin`
   - `BigQuery Admin`
   - `Dataproc Editor`
4. Create JSON key and download it
5. Save it at:

```text
secrets/gcp-sa-key.json
```

### Verify
- File exists at `secrets/gcp-sa-key.json`
- Never commit this file

---

## Step 7: Configure `.env`

### Action
1. Copy template:

```powershell
Copy-Item .env.example .env
```

2. Edit `.env` values:
- `KAGGLE_API_TOKEN`
- `GCP_PROJECT_ID`
- `GCP_SA_KEY_PATH=./secrets/gcp-sa-key.json`
- `GCS_BUCKET_NAME` (base name without env suffix)
- `BQ_DATASET`
- `ENVIRONMENT=staging`

### Verify

```powershell
Get-Content .env
```

Expected:
- No placeholder values left for required keys

---

## Step 8: Configure Terraform Variables

### Action
Edit:
- `terraform/envs/staging.tfvars`
- `terraform/envs/prod.tfvars`

Set `project_id` and other values to match your environment.

### Verify
- `project_id` is correct in both files
- `environment` is `staging` in staging and `prod` in prod

---

## Step 9: Terraform Dry Run (Staging)

### Action

```powershell
cd terraform
terraform init
terraform plan -var-file=envs/staging.tfvars
cd ..
```

### Verify
- `terraform init` succeeds
- `terraform plan` succeeds and shows resources to be created (bucket, dataset, dataproc cluster)

---

## Step 10: Terraform Apply (Staging)

### Action

```powershell
cd terraform
terraform apply -var-file=envs/staging.tfvars
cd ..
```

### Verify
In output, note created resource names.

Also verify in GCP Console:
- Cloud Storage bucket exists
- BigQuery dataset exists
- Dataproc cluster exists

---

## Step 11: Kaggle Data Download

### Action

```powershell
.\dezcamp\Scripts\activate
python scripts/download_from_kaggle.py
```

### Verify
- CSV files appear in `data/raw/`
- Main file `2019-Oct.csv` exists

---

## Step 12: Create 1-Week Dev Subset

### Action

```powershell
python scripts/create_dev_subset.py
```

### Verify
- `data/raw/dev_subset.csv` exists
- Script prints row count and file size

---

## Step 13: Upload Raw Data To GCS (Staging)

### Action

```powershell
python scripts/upload_to_gcs.py
```

### Verify
- Upload success messages in terminal
- In GCS console, files exist under `raw/`

---

## Step 14: Start Airflow Locally

### Action

```powershell
cd airflow
docker compose build
docker compose up -d
cd ..
```

### Verify
- Open [http://localhost:8080](http://localhost:8080)
- Login works with `admin / admin`
- Containers are healthy:

```powershell
cd airflow
docker compose ps
cd ..
```

---

## Step 15: Final Phase 1 Checklist

Mark complete when all are true:
- [ ] `dezcamp` venv works and dependencies installed
- [ ] `terraform --version` and `gcloud --version` work
- [ ] GCP project + APIs + billing configured
- [ ] Service account key is in `secrets/gcp-sa-key.json`
- [ ] `.env` configured with real values
- [ ] `terraform plan/apply` for staging succeeds
- [ ] Dataset downloaded to `data/raw/`
- [ ] `dev_subset.csv` created
- [ ] GCS upload succeeds
- [ ] Airflow opens at `localhost:8080`

When all boxes are checked, Phase 1 is complete and you can start Phase 2.

---

## Common Problems And Fixes

- **`terraform` not recognized**
  - Reopen terminal after adding to `PATH`
  - Confirm path contains folder with `terraform.exe`

- **`gcloud` not recognized**
  - Reopen terminal after install
  - Re-run installer if needed

- **Kaggle authentication error**
  - Ensure `KAGGLE_API_TOKEN` is present in `.env`
  - Re-activate venv and rerun script

- **GCP permission denied**
  - Check service account roles
  - Ensure `GCP_SA_KEY_PATH` points to correct file

- **Airflow on Windows warning**
  - Expected when importing Airflow directly on Windows
  - For runtime, use Docker containers (as configured)

- **Terraform apply is expensive if left running**
  - Destroy staging resources when idle:

```powershell
cd terraform
terraform destroy -var-file=envs/staging.tfvars
cd ..
```
