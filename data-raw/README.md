# Data Preparation Scripts

This directory contains scripts for preparing and generating the clinical trial
datasets included in the package.

## Scripts

### prepare_cdisc_pilot.R

Downloads and converts CDISC Pilot 01 study data from XPT format to Parquet format.
Also creates the combined ADLB dataset from ADLBC, ADLBH, and ADLBHY.

**Usage:**
```r
source("data-raw/prepare_cdisc_pilot.R")
```

**Output:** `inst/exampledata/cdisc_pilot/`

### create_extended_datasets.R

Creates extended versions of the CDISC Pilot datasets with additional derived
variables and the ADLBURI urinalysis dataset. Also creates the combined ADLB
dataset from ADLBC, ADLBH, ADLBHY, and ADLBURI.

**Usage:**
```r
source("data-raw/create_extended_datasets.R")
```

**Output:** `inst/exampledata/cdisc_pilot_extended/`

## Study Folder Lock Mechanism

### Purpose

The lock mechanism prevents data-raw scripts from accidentally overwriting study folders after the package has been installed. This protects the integrity of installed data.

### How It Works

1. **Automatic Locking**: When the package is installed (not in development
   mode), the `.onLoad()` hook automatically creates `.lock` files in each
   study folder under `inst/exampledata/`.

2. **Script Protection**: Data preparation scripts check for lock files before
   writing. If a folder is locked, the script will stop with an informative
   error message.

3. **Development Mode**: Lock files are not created when the package is loaded
   in development mode (i.e., when using `devtools::load_all()`).

### Managing Locks

#### Check Lock Status

```r
library(ctdata)
status <- get_lock_status("inst/exampledata/cdisc_pilot")
print(status)
```

#### Unlock a Study Folder

To regenerate data, you must first unlock the study folder:

```r
library(ctdata)
unlock_study("inst/exampledata/cdisc_pilot")

# Now you can run the data preparation script
source("data-raw/prepare_cdisc_pilot.R")
```

#### Lock a Study Folder

Manually lock a study folder to protect it:

```r
# Source the lock functions (in development)
source("R/lock.R")
lock_study("inst/exampledata/cdisc_pilot", reason = "Custom protection")
```

### Lock File Format

Lock files (`.lock`) are simple text files containing metadata:

```text
# Study folder lock file
# Created: 2025-10-23 11:29:45
# Reason: Package installed - protecting data from overwrites
# Hostname: COMPUTER-NAME
# User: username
# R version: 4.5.1

# This file prevents data-raw scripts from overwriting this study folder.
# To unlock, delete this file.
```

## Workflow for Updating Data

When you need to update or regenerate study data:

1. **Unlock the folder:**
   ```r
   library(ctdata)
   unlock_study("inst/exampledata/cdisc_pilot_extended")
   ```

2. **Run the data preparation script:**
   ```r
   source("data-raw/create_extended_datasets.R")
   ```

3. **Optionally lock again:**
   ```r
   source("R/lock.R")
   lock_study("inst/exampledata/cdisc_pilot_extended", "Updated data")
   ```

## Notes

- Lock files are automatically excluded from the package build via `.Rbuildignore`
- Lock files are not tracked in git (they are generated at install time)
- In development mode (using `devtools`), locks are not created automatically
- You can manually delete `.lock` files if needed, but using `unlock_study()`
  is preferred
