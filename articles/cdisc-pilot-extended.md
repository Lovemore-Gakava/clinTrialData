# CDISC Pilot Extended Datasets

## Introduction

The `cdisc_pilot_extended` data source provides an enhanced version of
the CDISC Pilot Study data with additional derived variables and a new
urinalysis dataset (ADLBURI). This data source is designed to support
more advanced clinical data analysis scenarios and demonstrate
additional CDISC ADaM conventions.

## What’s New in the Extended Datasets

The extended datasets include several enhancements over the standard
CDISC Pilot data:

### Additional Variables

1.  **TRTDURY**: Treatment duration in years (derived from TRTDUR by
    dividing by 365.25)
    - Available in: ADSL, ADTTE
    - Useful for: Long-term exposure analysis, time-to-event modeling

### New Dataset: ADLBURI (Urinalysis)

A new laboratory dataset focusing on urinalysis parameters.

## Installation and Setup

``` r
# Install the package
remotes::install_github("lovemore-gakava/clinTrialData")

library(clinTrialData)
```

## Quick Start

### Connect to the Extended Data Source

``` r
library(clinTrialData)
library(dplyr)
library(ggplot2)

# Connect to the extended CDISC Pilot data
db <- connect_clinical_data("cdisc_pilot_extended")

# List available ADaM datasets
db$adam$list_content_cnt()
```

### Available Datasets

All datasets from the standard CDISC Pilot data are included, plus:

**ADaM Datasets:**

- **ADSL** - Subject-Level Analysis Dataset (with TRTDURY)
- **ADTTE** - Time-to-Event Analysis Dataset (with TRTDURY)
- **ADLB** - Combined laboratory data (chemistry, hematology, Hy’s Law,
  urinalysis)
- **ADLBC, ADLBH, ADLBHY** - Individual laboratory datasets
- **ADAE** - Adverse events
- **ADVS** - Vital signs
- **ADQSADAS, ADQSCIBC, ADQSNPIX** - Questionnaire data
- **ADLBURI** - Urinalysis (new!)

**SDTM Datasets:**

All standard SDTM datasets (DM, AE, VS, LB, CM, DS, EX, MH, QS, SC, SE,
SV, SUPPAE, SUPPDM, SUPPDS, SUPPLB, TA, TE, TI, TS, TV, RELREC)

## Contributing to Extended Data

The extended datasets are generated using
`data-raw/create_extended_datasets.R`. If you would like to modify or
enhance the extended datasets, you can do so by:

1.  **Fork the repository** on GitHub or **create a pull request**
2.  In your fork/branch, modify the script
    `data-raw/create_extended_datasets.R`
3.  Run the script to regenerate the datasets
4.  Submit a pull request with your enhancements

**Note:** Extended datasets cannot be modified in an installed package
directly. Contributions must be made through the package development
workflow (fork/PR).

To contribute, visit the [GitHub
repository](https://github.com/Lovemore-Gakava/clinTrialData).

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

## Next Steps

- Explore the [Getting
  Started](https://lovemore-gakava.github.io/clinTrialData/articles/getting-started.md)
  vignette for basic package usage
- Review the standard CDISC Pilot data for comparison
- Use these extended datasets to develop and test advanced analysis
  workflows
- Contribute your own extensions and analysis examples

## Support

For questions, issues, or contributions, please visit the [GitHub
repository](https://github.com/Lovemore-Gakava/clinTrialData).
