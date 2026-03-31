"""Upload raw CSV files from data/raw/ to GCS bucket.

Requires GCP_SA_KEY_PATH and GCS_BUCKET_NAME env vars.
"""

import os
import sys
from pathlib import Path

from dotenv import load_dotenv
from google.cloud import storage

load_dotenv()

DEFAULT_DATA_DIR = Path(__file__).resolve().parent.parent / "data" / "raw"


def upload_to_gcs(
    data_dir: Path = DEFAULT_DATA_DIR,
    bucket_name: str | None = None,
    prefix: str = "raw",
) -> None:
    bucket_name = bucket_name or os.getenv("GCS_BUCKET_NAME")
    sa_key_path = os.getenv("GCP_SA_KEY_PATH")

    if not bucket_name:
        print("ERROR: GCS_BUCKET_NAME not set.")
        sys.exit(1)

    env = os.getenv("ENVIRONMENT", "staging")
    full_bucket_name = f"{bucket_name}-{env}"

    if sa_key_path:
        client = storage.Client.from_service_account_json(sa_key_path)
    else:
        client = storage.Client()

    bucket = client.bucket(full_bucket_name)

    csv_files = list(data_dir.glob("*.csv"))
    if not csv_files:
        print(f"No CSV files found in {data_dir}")
        sys.exit(1)

    for csv_file in csv_files:
        blob_name = f"{prefix}/{csv_file.name}"
        blob = bucket.blob(blob_name)

        size_mb = csv_file.stat().st_size / (1024 * 1024)
        print(f"Uploading {csv_file.name} ({size_mb:.1f} MB) to gs://{full_bucket_name}/{blob_name} ...")

        blob.upload_from_filename(str(csv_file), timeout=600)
        print("  Uploaded successfully.")

    print(f"\nAll files uploaded to gs://{full_bucket_name}/{prefix}/")


if __name__ == "__main__":
    upload_to_gcs()
