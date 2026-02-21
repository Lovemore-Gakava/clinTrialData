# Getting Started with clinTrialData

## Introduction

`clinTrialData` is a **community-grown library** of clinical trial
example datasets for R. The package ships with a core set of studies and
is designed to expand over time — anyone can contribute a new data
source, and users can download any available study on demand without
waiting for a new package release.

Data is stored in Parquet format and accessed through the `connector`
package, giving a consistent API regardless of which study you are
working with.

Key features:

- **Growing library**: New datasets are added by the community as GitHub
  Release assets — no CRAN resubmission needed
- **On-demand download**: Use
  [`download_study()`](https://lovemore-gakava.github.io/clinTrialData/reference/download_study.md)
  to fetch any available study and cache it locally
- **Generic interface**: Use
  [`connect_clinical_data()`](https://lovemore-gakava.github.io/clinTrialData/reference/connect_clinical_data.md)
  to connect to any available data source
- **Automatic discovery**:
  [`list_data_sources()`](https://lovemore-gakava.github.io/clinTrialData/reference/list_data_sources.md)
  finds all studies on your machine;
  [`list_available_studies()`](https://lovemore-gakava.github.io/clinTrialData/reference/list_available_studies.md)
  shows everything available to download
- **Data protection**: Downloaded and bundled datasets are locked
  against accidental modification

## Installation

``` r
# Install from CRAN
install.packages("clinTrialData")

# Or the development version from GitHub:
# install.packages("remotes")
remotes::install_github("Lovemore-Gakava/clinTrialData")
```

## Available Data Sources

``` r
library(clinTrialData)

# Studies on your machine (bundled + previously downloaded)
list_data_sources()
#>        source          description    domains  format location
#> 1 cdisc_pilot CDISC Pilot 01 Study adam, sdtm parquet  bundled
```

## Quick Start

### Discover and Download Data Sources

``` r
# What's on your machine already?
list_data_sources()

# What's available to download from GitHub Releases?
list_available_studies()

# Download a study once — cached locally from then on
download_study("cdisc_pilot")

# Where is the cache?
cache_dir()
```

### Connect to a Data Source

``` r
# Connect to CDISC Pilot data (or any available source)
db <- connect_clinical_data("cdisc_pilot")

# List available datasets in ADaM domain
db$adam$list_content_cnt()

# Read ADSL dataset
adsl <- db$adam$read_cnt("adsl")
head(adsl)
```

### Explore the Data

``` r
# Get dataset dimensions
dim(adsl)

# View structure
str(adsl)

# Summary statistics
summary(adsl)
```

## Working with Different Domains

### ADaM Datasets

``` r
# Read adverse events data
adae <- db$adam$read_cnt("adae")

# Read lab data
adlbc <- db$adam$read_cnt("adlbc")
```

### SDTM Datasets

``` r
# Read demographics
dm <- db$sdtm$read_cnt("dm")

# Read vital signs
vs <- db$sdtm$read_cnt("vs")
```

## Working with Multiple Data Sources

The package automatically discovers all available data sources. You can
easily switch between different sources or work with multiple sources
simultaneously:

``` r
# Get information about all sources
all_sources <- list_data_sources()

# Connect to different sources
for (source_name in all_sources$source) {
  cat("Connecting to:", source_name, "\n")
  db <- connect_clinical_data(source_name)

  # List domains available in this source
  cat("Available domains:", names(db), "\n")
}
```

## Example Analysis

``` r
library(dplyr)

# Connect to data source
db <- connect_clinical_data("cdisc_pilot")

# Read subject-level data
adsl <- db$adam$read_cnt("adsl")

# Basic demographic summary by treatment
demo_summary <- adsl %>%
  group_by(TRT01A) %>%
  summarise(
    n = n(),
    mean_age = mean(AGE, na.rm = TRUE),
    female_pct = mean(SEX == "F", na.rm = TRUE) * 100,
    .groups = "drop"
  )

print(demo_summary)
```

## Contributing New Data Sources

Anyone can add a new study to the library. Datasets live on [GitHub
Releases](https://github.com/Lovemore-Gakava/clinTrialData/releases),
not inside the package — so **no pull request or CRAN submission is
needed** to add data.

### Step 1: Prepare your data

Organise your Parquet files by domain:

    your_new_study/
    ├── adam/
    │   ├── adsl.parquet
    │   └── adae.parquet
    └── sdtm/
        ├── dm.parquet
        └── ae.parquet

### Step 2: Upload data and metadata to a GitHub Release

Open an [issue](https://github.com/Lovemore-Gakava/clinTrialData/issues)
to request a release slot, then use the helper script:

``` r
source("data-raw/upload_to_release.R")

# Upload the data zip
upload_study_to_release("your_new_study", tag = "v1.1.0")

# Generate and upload metadata (enables dataset_info() for your study)
generate_and_upload_metadata(
  source      = "your_new_study",
  description = "Brief description of your study",
  version     = "v1.1.0",
  license     = "Your license here",
  source_url  = "https://link-to-original-data",
  tag         = "v1.1.0"
)
```

### Step 3: Users can inspect and access it immediately

``` r
dataset_info("your_new_study")       # inspect before downloading
download_study("your_new_study")     # download and cache
connect_clinical_data("your_new_study")
```

No CRAN submission required. The study is available to all users as soon
as it is uploaded.
