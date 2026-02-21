# clinTrialData

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
# What's available to download from GitHub Releases?
list_available_studies()
#>                  source version size_mb cached
#> 1           cdisc_pilot  v0.1.0     3.7   TRUE
#> 2  cdisc_pilot_extended  v0.1.0     4.3  FALSE

# Inspect any study before downloading — fetches a tiny metadata file
dataset_info("cdisc_pilot_extended")
#> ──────────────────────────────────────────────────────────────────────────
#> cdisc_pilot_extended (v0.1.0)
#> ──────────────────────────────────────────────────────────────────────────
#> Enhanced CDISC Pilot 01 study with urinalysis data
#>
#> Domains & datasets:
#>   adam   (12): adsl, adae, adlb, adlbc, adlbh, adlbhy, adlburi, ...
#>   sdtm   (22): ae, cm, dm, ds, ex, lb, mh, qs, relrec, sc, ...
#>
#> Subjects:   254
#> Version:    v0.1.0
#> License:    CDISC Pilot — educational use
#> Source:     https://github.com/cdisc-org/sdtm-adam-pilot-project
#> ──────────────────────────────────────────────────────────────────────────

# Download once; cached locally from then on
download_study("cdisc_pilot_extended")

# Connect and analyse — same API for every study
db <- connect_clinical_data("cdisc_pilot_extended")
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

## Available Data Sources

### Bundled with the package

**cdisc_pilot** — Standard CDISC Pilot 01 study (10 ADaM, 22 SDTM
datasets). Available immediately after installation, no download needed.

### Available via GitHub Releases

**cdisc_pilot_extended** — Enhanced CDISC Pilot 01 study (11 ADaM, 24
SDTM datasets) with additional features:

- **TRTDURY** — Treatment duration in years
- **ADLBURI** — Urinalysis laboratory dataset
- **ADLB** — Combined labs including urinalysis

``` r
download_study("cdisc_pilot_extended")
connect_clinical_data("cdisc_pilot_extended")
```

Use
[`list_data_sources()`](https://lovemore-gakava.github.io/clinTrialData/reference/list_data_sources.md)
to see all locally available studies and
[`list_available_studies()`](https://lovemore-gakava.github.io/clinTrialData/reference/list_available_studies.md)
to see everything on GitHub Releases.

## Contributing a New Data Source

Adding a new study to the library does not require a pull request or a
CRAN submission. The data lives on GitHub Releases, not inside the
package.

1.  **Prepare your data** as Parquet files organised by domain
    (e.g. `adam/`, `sdtm/`):

``` R
your_study/
├── adam/
│   ├── adsl.parquet
│   └── adae.parquet
└── sdtm/
    ├── dm.parquet
    └── ae.parquet
```

2.  **Upload to a GitHub Release** — open an issue on the
    [repository](https://github.com/Lovemore-Gakava/clinTrialData/issues)
    to request a release slot, then use the helper script:

``` r
source("data-raw/upload_to_release.R")

# Upload the data zip
upload_study_to_release("your_study", tag = "v1.1.0")

# Generate and upload the metadata (enables dataset_info() for your study)
generate_and_upload_metadata(
  source      = "your_study",
  description = "Brief description of your study",
  version     = "v1.1.0",
  license     = "Your license here",
  source_url  = "https://link-to-original-data",
  tag         = "v1.1.0"
)
```

3.  **Users can inspect and access it immediately** — no CRAN submission
    required:

``` r
dataset_info("your_study")      # inspect before downloading
download_study("your_study")    # download and cache
connect_clinical_data("your_study")
```

## Data Protection

All datasets — whether bundled or downloaded — are automatically
protected from accidental modification. Reading is always allowed; write
and delete operations are blocked with a clear error message.

## Data Attribution

The extended datasets are derived from the CDISC Pilot Study data.

**Original Source**: [CDISC SDTM/ADaM Pilot
Project](https://github.com/cdisc-org/sdtm-adam-pilot-project)

**Modifications**: This extended version includes additional derived
variables (TRTDURY) and a simulated urinalysis dataset (ADLBURI) created
for educational and development purposes.

**Acknowledgments**: We acknowledge and thank CDISC for making the
original pilot data available. The extended datasets maintain the
structure and quality of the original data while adding features to
support additional analysis scenarios.

## Documentation

``` r
# Browse all vignettes
vignette(package = "clinTrialData")

# Cache location
cache_dir()
```
