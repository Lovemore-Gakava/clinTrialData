
<!-- README.md is generated from README.Rmd. Please edit that file -->

# clinTrialData <img src="man/figures/logo.png" align="right" height="139" alt="clinTrialData logo" />

<!-- badges: start -->

[![R-CMD-check](https://github.com/Lovemore-Gakava/clinTrialData/actions/workflows/r.yml/badge.svg)](https://github.com/Lovemore-Gakava/clinTrialData/actions/workflows/r.yml)
<!-- badges: end -->

`clinTrialData` is a **community-grown library** of clinical trial
example datasets for R. The package ships with a core set of datasets
and is designed to expand over time — anyone can contribute a new data
source, and users can download any available study on demand without
waiting for a new package release.

Data is stored in Parquet format and accessed through the
[`connector`](https://github.com/pharmaverse/connector) package, giving
a consistent API regardless of which study you are working with.

## How the library grows

The core idea is simple: datasets live as assets on [GitHub
Releases](https://github.com/Lovemore-Gakava/clinTrialData/releases),
not inside the package itself. This means:

- **Users** can pull in any study with a single function call
- **Contributors** can add new datasets without a CRAN resubmission
- **The library expands** as the community adds more real-world clinical
  trial examples

``` r
# See everything available — bundled in the package or ready to download
list_available_studies()
#>                  source version size_mb cached
#> 1           cdisc_pilot   1.0.0     9.2   TRUE
#> 2  cdisc_pilot_extended   1.0.0     9.2  FALSE
#> 3        new_study_2025   1.1.0     4.8  FALSE

# Download a study once; it's cached locally from then on
download_study("new_study_2025")

# Connect and analyse — same API for every study
db <- connect_clinical_data("new_study_2025")
adsl <- db$adam$read_cnt("adsl")
```

## Installation

``` r
# Install from CRAN
install.packages("clinTrialData")

# Or the development version from GitHub:
# install.packages("remotes")
remotes::install_github("Lovemore-Gakava/clinTrialData")
```

## Quick Start

``` r
library(clinTrialData)

# What's already on your machine?
list_data_sources()

# What's available to download?
list_available_studies()

# Download a study (only needed once — cached locally after that)
download_study("cdisc_pilot")

# Connect and explore
db <- connect_clinical_data("cdisc_pilot")

db$adam$list_content_cnt()  # list ADaM datasets
db$sdtm$list_content_cnt()  # list SDTM datasets

adsl <- db$adam$read_cnt("adsl")
dm   <- db$sdtm$read_cnt("dm")
```

## Bundled Data Sources

The following studies ship with the package and are available
immediately after installation.

### cdisc_pilot

Standard CDISC Pilot 01 study — 10 ADaM and 22 SDTM datasets, widely
used for training and prototyping.

### cdisc_pilot_extended

An enhanced version of the CDISC Pilot 01 study — 11 ADaM and 24 SDTM
datasets with additional features:

- **TRTDURY** — Treatment duration in years
- **ADLBURI** — Urinalysis laboratory dataset
- **ADLB** — Combined labs including urinalysis

Use `list_data_sources()` to see all locally available studies and their
domains.

## Contributing a New Data Source

Adding a new study to the library takes three steps:

1.  **Prepare your data** as Parquet files organised by domain
    (e.g. `adam/`, `sdtm/`), following the structure of the existing
    studies in `inst/exampledata/`.

2.  **Open a pull request** adding your study folder to
    `inst/exampledata/` and a preparation script to `data-raw/`. See the
    [contributing
    guide](https://lovemore-gakava.github.io/clinTrialData/CONTRIBUTING.html)
    for details.

3.  **Upload to a release** using the helper script in
    `data-raw/upload_to_release.R`:

``` r
# After your PR is merged, upload the study as a release asset:
source("data-raw/upload_to_release.R")
upload_study_to_release("your_study_name", tag = "v1.1.0")
```

Once uploaded, any user can access your study immediately via
`download_study("your_study_name")` — no CRAN submission required.

## Data Protection

All datasets — whether bundled or downloaded — are automatically
protected from accidental modification. Reading is always allowed; write
and delete operations are blocked with a clear error message.

## Documentation

``` r
# Browse all vignettes
vignette(package = "clinTrialData")

# Extended dataset guide
vignette("cdisc-pilot-extended", package = "clinTrialData")

# Cache location
cache_dir()
```
