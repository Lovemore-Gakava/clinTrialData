# List Studies Available for Download

Returns a data frame of all clinical trial studies available as GitHub
Release assets, along with their local cache status. Studies marked as
`cached = TRUE` are already downloaded and available for use with
[`connect_clinical_data()`](https://lovemore-gakava.github.io/clinTrialData/reference/connect_clinical_data.md)
without an internet connection.

When GitHub is unreachable, the function falls back to the last
successfully fetched listing (if available) and issues a warning. The
`cached` column is always recomputed from the local filesystem.

Requires the `piggyback` package.

## Usage

``` r
list_available_studies(repo = "Lovemore-Gakava/clinTrialData")
```

## Arguments

- repo:

  GitHub repository in the form `"owner/repo"`. Defaults to the official
  `clinTrialData` release repository.

## Value

A data frame with columns:

- source:

  Study name (pass this to
  [`download_study()`](https://lovemore-gakava.github.io/clinTrialData/reference/download_study.md)
  or
  [`connect_clinical_data()`](https://lovemore-gakava.github.io/clinTrialData/reference/connect_clinical_data.md))

- version:

  Release tag the asset belongs to

- size_mb:

  Asset size in megabytes

- cached:

  `TRUE` if the study is already in the local cache

## Examples

``` r
if (FALSE) { # \dontrun{
list_available_studies()
} # }
```
