# SQL Data Cleaning — Client Trading Dataset

MySQL data cleaning project using a deliberately messy client trading dataset. The objective was to identify data quality issues, clean and standardize the dataset, and validate the final table.

## Dataset

The dataset contains client trading account information, including:

- `ta_id` — unique trading account ID
- `poa` — Proof of Address status
- `poi` — Proof of Identity status
- `registration_time`
- `ib_id` — Introducing Broker ID
- `region` 
- `initial_deposit`
- `swap_free_status`
- `pnl`
- `nb_of_trades`
- `volume`
- `most_traded_symbol`

The original CSV was intentionally created with various data quality issues to simulate a real-world messy dataset.

## Data Quality Issues Identified

The dataset contained several types of inconsistencies and errors:

- 100% identical duplicate rows
- Duplicate `ta_id` values where only one record should exist
- Missing values represented as blanks and `N/A`
- Three different formats for `registration_time`
- Two malformed `ib_id` values containing region text
- Missing region values caused by the malformed `ib_id` entries
- Negative and unusually high `initial_deposit` values
- Formatting inconsistencies in `nb_of_trades` including commas and `k` notation
- Inconsistent capitalization in `most_traded_symbol`
- All columns were initially imported as text to prevent formatting issues or accidental data loss during import

## Cleaning Process

### 1. Preserve the Raw Data

Created an identical working table from the original imported table so that the raw data remained untouched.

A surrogate `id` column was then added as an `AUTO_INCREMENT` primary key to uniquely identify individual rows during the cleaning process.

### 2. Duplicate Detection and Removal

- Identified duplicate `ta_id` values.
- Identified rows that were completely identical across all relevant columns.
- Removed exact duplicates while retaining one copy.
- Investigated the remaining duplicate `ta_id`.
- One duplicate contained complete information while the other was missing important entries, so the incomplete record was removed.

### 3. POA and POI Validation

Checked the distinct values for `poa` and `poi`.

Both columns contained only:

- `Yes`
- `No`

No changes were required.

### 4. Registration Time Standardization

The `registration_time` column contained three different date/time formats as well as blank and `N/A` values.

The cleaning process:

- Converted blank and `N/A` values to `NULL`
- Converted the different date formats into a consistent `DATETIME` format
- Verified the resulting values

### 5. IB ID and Region Cleaning

Inspected distinct `ib_id` values and identified two malformed entries:

- `40404Europe`
- `40405APAC`

The malformed IB IDs were corrected, and the corresponding missing `region` values were populated based on the information contained in the original entries.

The `region` column was then rechecked to confirm consistency.

### 6. Numeric Data Validation

Numeric columns were inspected by casting values to numeric formats and sorting them to identify potential formatting or value issues.

Regular expressions were also used to identify values that did not follow the expected numeric format.

#### Initial Deposit

Identified negative and unusually high deposit values.

For this dataset, negative deposits and values above the defined threshold of 500,000 were treated as invalid and replaced with `0`.

#### P&L

Inspected and validated the `pnl` values. No significant formatting issues were identified.

#### Number of Trades

Identified formatting inconsistencies including:

- Comma-separated values such as `1,232`
- `k` notation such as `1.75k`

These were converted into standard numeric values.

#### Volume

Validated the values against the expected decimal format. No issues requiring correction were identified.

### 7. Swap-Free Status

Checked the distinct values in `swap_free_status`.

The column contained only `Yes` and `No`, so no changes were required.

### 8. Trading Symbol Standardization

Identified inconsistent capitalization in `most_traded_symbol`.

All symbols were standardized to uppercase.

### 9. Final Data Types

After the cleaning process was completed, the final table was inspected and the columns were converted from their initial text-based format into appropriate data types, including:

- `INT`
- `DECIMAL`
- `DATETIME`
- `ENUM`
- `VARCHAR`

The final schema was then inspected to verify that the data types were correctly applied.

## SQL Techniques Used

- `SELECT`
- `GROUP BY` / `HAVING`
- `JOIN`
- `UPDATE`
- `DELETE`
- `ALTER TABLE`
- `CAST`
- `STR_TO_DATE`
- `REGEXP`
- `REPLACE`
- `UPPER`
- `DISTINCT`
- `ENUM`
- `DATETIME`

## Repository Structure

```text
sql-data-cleaning/
├── README.md
├── data/
│   └── raw_clients.csv
└── sql/
    └── data_cleaning.sql
