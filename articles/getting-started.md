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
#>        source
#> 1 cdisc_pilot
#>                                                                                       description
#> 1 CDISC Pilot 01 Study — standard ADaM and SDTM datasets widely used for training and prototyping
#>      domains  format location
#> 1 adam, sdtm parquet  bundled
```

## Quick Start

### Connect to a Data Source

The package bundles the CDISC Pilot 01 study, so you can connect
immediately:

``` r
# Connect to CDISC Pilot data
db <- connect_clinical_data("cdisc_pilot")
#> ℹ Replace some metadata informations...
#> ────────────────────────────────────────────────────────────────────────────────
#> Connection to:
#> → adam
#> • connector_fs
#> • /home/runner/work/_temp/Library/clinTrialData/exampledata/cdisc_pilot/adam
#> ────────────────────────────────────────────────────────────────────────────────
#> Connection to:
#> → sdtm
#> • connector_fs
#> • /home/runner/work/_temp/Library/clinTrialData/exampledata/cdisc_pilot/sdtm

# List available datasets in the ADaM domain
db$adam$list_content_cnt()
#>  [1] "adae.parquet"     "adlb.parquet"     "adlbc.parquet"    "adlbh.parquet"   
#>  [5] "adlbhy.parquet"   "adqsadas.parquet" "adqscibc.parquet" "adqsnpix.parquet"
#>  [9] "adsl.parquet"     "adtte.parquet"    "advs.parquet"

# Read the subject-level dataset
adsl <- db$adam$read_cnt("adsl")
#> → Found one file: /home/runner/work/_temp/Library/clinTrialData/exampledata/cdisc_pilot/adam/adsl.parquet
head(adsl[, c("USUBJID", "TRT01A", "AGE", "SEX", "RACE")])
#> # A tibble: 6 × 5
#>   USUBJID     TRT01A                 AGE SEX   RACE 
#>   <chr>       <chr>                <dbl> <chr> <chr>
#> 1 01-701-1015 Placebo                 63 F     WHITE
#> 2 01-701-1023 Placebo                 64 M     WHITE
#> 3 01-701-1028 Xanomeline High Dose    71 M     WHITE
#> 4 01-701-1033 Xanomeline Low Dose     74 M     WHITE
#> 5 01-701-1034 Xanomeline High Dose    77 F     WHITE
#> 6 01-701-1047 Placebo                 85 F     WHITE
```

### Discover and Download Additional Studies

Studies beyond the bundled data can be downloaded from GitHub Releases:

``` r
# What's available to download?
list_available_studies()

# Download a study once — cached locally from then on
download_study("cdisc_pilot_extended")

# Where is the cache?
cache_dir()
```

### Explore the Data

``` r
# Dimensions
dim(adsl)
#> [1] 254  48

# Quick structure overview
str(adsl, list.len = 10)
#> tibble [254 × 48] (S3: tbl_df/tbl/data.frame)
#>  $ STUDYID : chr [1:254] "CDISCPILOT01" "CDISCPILOT01" "CDISCPILOT01" "CDISCPILOT01" ...
#>   ..- attr(*, "label")= chr "Study Identifier"
#>  $ USUBJID : chr [1:254] "01-701-1015" "01-701-1023" "01-701-1028" "01-701-1033" ...
#>   ..- attr(*, "label")= chr "Unique Subject Identifier"
#>  $ SUBJID  : chr [1:254] "1015" "1023" "1028" "1033" ...
#>   ..- attr(*, "label")= chr "Subject Identifier for the Study"
#>  $ SITEID  : chr [1:254] "701" "701" "701" "701" ...
#>   ..- attr(*, "label")= chr "Study Site Identifier"
#>  $ SITEGR1 : chr [1:254] "701" "701" "701" "701" ...
#>   ..- attr(*, "label")= chr "Pooled Site Group 1"
#>  $ ARM     : chr [1:254] "Placebo" "Placebo" "Xanomeline High Dose" "Xanomeline Low Dose" ...
#>   ..- attr(*, "label")= chr "Description of Planned Arm"
#>  $ TRT01P  : chr [1:254] "Placebo" "Placebo" "Xanomeline High Dose" "Xanomeline Low Dose" ...
#>   ..- attr(*, "label")= chr "Planned Treatment for Period 01"
#>  $ TRT01PN : num [1:254] 0 0 81 54 81 0 54 54 54 0 ...
#>   ..- attr(*, "label")= chr "Planned Treatment for Period 01 (N)"
#>  $ TRT01A  : chr [1:254] "Placebo" "Placebo" "Xanomeline High Dose" "Xanomeline Low Dose" ...
#>   ..- attr(*, "label")= chr "Actual Treatment for Period 01"
#>  $ TRT01AN : num [1:254] 0 0 81 54 81 0 54 54 54 0 ...
#>   ..- attr(*, "label")= chr "Actual Treatment for Period 01 (N)"
#>   [list output truncated]
```

## Working with Different Domains

### ADaM Datasets

``` r
# Read adverse events data
adae <- db$adam$read_cnt("adae")
#> → Found one file: /home/runner/work/_temp/Library/clinTrialData/exampledata/cdisc_pilot/adam/adae.parquet
head(adae[, c("USUBJID", "AEDECOD", "AESEV", "AESER")])
#> # A tibble: 6 × 4
#>   USUBJID     AEDECOD                              AESEV    AESER
#>   <chr>       <chr>                                <chr>    <chr>
#> 1 01-701-1015 APPLICATION SITE ERYTHEMA            MILD     N    
#> 2 01-701-1015 APPLICATION SITE PRURITUS            MILD     N    
#> 3 01-701-1015 DIARRHOEA                            MILD     N    
#> 4 01-701-1023 ERYTHEMA                             MILD     N    
#> 5 01-701-1023 ERYTHEMA                             MODERATE N    
#> 6 01-701-1023 ATRIOVENTRICULAR BLOCK SECOND DEGREE MILD     N
```

### SDTM Datasets

``` r
# Read demographics
dm <- db$sdtm$read_cnt("dm")
#> → Found one file: /home/runner/work/_temp/Library/clinTrialData/exampledata/cdisc_pilot/sdtm/dm.parquet
head(dm[, c("USUBJID", "ARM", "AGE", "SEX", "RACE")])
#> # A tibble: 6 × 5
#>   USUBJID     ARM                    AGE SEX   RACE 
#>   <chr>       <chr>                <dbl> <chr> <chr>
#> 1 01-701-1015 Placebo                 63 F     WHITE
#> 2 01-701-1023 Placebo                 64 M     WHITE
#> 3 01-701-1028 Xanomeline High Dose    71 M     WHITE
#> 4 01-701-1033 Xanomeline Low Dose     74 M     WHITE
#> 5 01-701-1034 Xanomeline High Dose    77 F     WHITE
#> 6 01-701-1047 Placebo                 85 F     WHITE
```

## Example Analysis

``` r
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union

# Basic demographic summary by treatment
adsl |>
  group_by(TRT01A) |>
  summarise(
    n = n(),
    mean_age = mean(AGE, na.rm = TRUE),
    female_pct = mean(SEX == "F", na.rm = TRUE) * 100,
    .groups = "drop"
  )
#> # A tibble: 3 × 4
#>   TRT01A                   n mean_age female_pct
#>   <chr>                <int>    <dbl>      <dbl>
#> 1 Placebo                 86     75.2       61.6
#> 2 Xanomeline High Dose    84     74.4       47.6
#> 3 Xanomeline Low Dose     84     75.7       59.5
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
