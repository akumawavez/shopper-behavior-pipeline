"""Create a 1-week subset of the raw dataset for local development.

Reads the full Oct 2019 CSV and filters to 2019-10-01 through 2019-10-07.
Writes the subset to data/raw/dev_subset.csv.
"""

import sys
from pathlib import Path

import pandas as pd

DEFAULT_DATA_DIR = Path(__file__).resolve().parent.parent / "data" / "raw"
SOURCE_FILE = "2019-Oct.csv"
OUTPUT_FILE = "dev_subset.csv"

START_DATE = "2019-10-01"
END_DATE = "2019-10-07"

CHUNK_SIZE = 500_000


def create_subset(
    data_dir: Path = DEFAULT_DATA_DIR,
    start_date: str = START_DATE,
    end_date: str = END_DATE,
) -> None:
    source_path = data_dir / SOURCE_FILE
    output_path = data_dir / OUTPUT_FILE

    if not source_path.exists():
        print(f"ERROR: Source file not found: {source_path}")
        print("Run 'make data-download' first.")
        sys.exit(1)

    print(f"Creating dev subset ({start_date} to {end_date}) ...")
    print(f"Reading from: {source_path}")

    total_rows = 0
    header_written = False

    for chunk in pd.read_csv(source_path, chunksize=CHUNK_SIZE, parse_dates=["event_time"]):
        mask = (chunk["event_time"] >= start_date) & (
            chunk["event_time"] < pd.Timestamp(end_date) + pd.Timedelta(days=1)
        )
        filtered = chunk[mask]

        if not filtered.empty:
            filtered.to_csv(
                output_path,
                mode="a" if header_written else "w",
                header=not header_written,
                index=False,
            )
            header_written = True
            total_rows += len(filtered)

        if chunk["event_time"].min() > pd.Timestamp(end_date) + pd.Timedelta(days=1):
            break

    size_mb = output_path.stat().st_size / (1024 * 1024) if output_path.exists() else 0
    print(f"Subset created: {output_path}")
    print(f"  Rows: {total_rows:,}")
    print(f"  Size: {size_mb:.1f} MB")


if __name__ == "__main__":
    create_subset()
