"""Download eCommerce behavior dataset from Kaggle.

Uses the KAGGLE_API_TOKEN env var for authentication.
Downloads to data/raw/ by default.
"""

import os
import sys
from pathlib import Path

from dotenv import load_dotenv

load_dotenv()

DATASET_SLUG = "mkechinov/ecommerce-behavior-data-from-multi-category-store"
DEFAULT_OUTPUT_DIR = Path(__file__).resolve().parent.parent / "data" / "raw"


def download_dataset(output_dir: Path = DEFAULT_OUTPUT_DIR) -> None:
    token = os.getenv("KAGGLE_API_TOKEN")
    if not token:
        print("ERROR: KAGGLE_API_TOKEN not set. Add it to your .env file.")
        sys.exit(1)

    os.environ["KAGGLE_KEY"] = token
    os.environ["KAGGLE_USERNAME"] = ""

    from kaggle.api.kaggle_api_extended import KaggleApi

    output_dir.mkdir(parents=True, exist_ok=True)

    api = KaggleApi()
    api.authenticate()

    print(f"Downloading dataset '{DATASET_SLUG}' to {output_dir} ...")
    api.dataset_download_files(DATASET_SLUG, path=str(output_dir), unzip=True)
    print("Download complete.")

    csv_files = list(output_dir.glob("*.csv"))
    for f in csv_files:
        size_mb = f.stat().st_size / (1024 * 1024)
        print(f"  {f.name}: {size_mb:.1f} MB")


if __name__ == "__main__":
    output = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_OUTPUT_DIR
    download_dataset(output)
