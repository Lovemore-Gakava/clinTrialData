# Download a Clinical Trial Study Dataset

Downloads a study dataset from a GitHub Release and stores it in the
local cache (see
[`cache_dir()`](https://lovemore-gakava.github.io/clinTrialData/reference/cache_dir.md)).
Once downloaded, the study is available to
[`connect_clinical_data()`](https://lovemore-gakava.github.io/clinTrialData/reference/connect_clinical_data.md)
without an internet connection.

Requires the `piggyback` package.

## Usage

``` r
download_study(
  source,
  version = "latest",
  force = FALSE,
  repo = "Lovemore-Gakava/clinTrialData"
)
```

## Arguments

- source:

  Character string. The name of the study to download (e.g.
  `"cdisc_pilot"`). Use
  [`list_available_studies()`](https://lovemore-gakava.github.io/clinTrialData/reference/list_available_studies.md)
  to see all options.

- version:

  Character string. The release tag to download from. Defaults to
  `"latest"`, which resolves to the most recent release.

- force:

  Logical. If `TRUE`, re-download even if the study is already cached.
  Defaults to `FALSE`.

- repo:

  GitHub repository in the form `"owner/repo"`. Defaults to the official
  `clinTrialData` release repository.

## Value

Invisibly returns the path to the cached study directory.

## Examples

``` r
if (FALSE) { # \dontrun{
# Download the CDISC Pilot study
download_study("cdisc_pilot")

# Force re-download a specific version
download_study("cdisc_pilot", version = "v1.0.0", force = TRUE)

# Then connect as usual
db <- connect_clinical_data("cdisc_pilot")
} # }
```
