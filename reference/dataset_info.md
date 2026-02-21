# Inspect a Clinical Trial Dataset Without Downloading

Fetches and displays metadata for any study available in the
`clinTrialData` library — without downloading the full dataset. Metadata
includes the study description, available domains and datasets, subject
count, version, and data source attribution.

For studies already downloaded via
[`download_study()`](https://lovemore-gakava.github.io/clinTrialData/reference/download_study.md),
the metadata is read from the local cache and works offline. For studies
not yet downloaded, a small JSON file (~2KB) is fetched from the GitHub
Release.

## Usage

``` r
dataset_info(source, repo = "Lovemore-Gakava/clinTrialData")
```

## Arguments

- source:

  Character string. Name of the study (e.g. `"cdisc_pilot_extended"`).
  Use
  [`list_available_studies()`](https://lovemore-gakava.github.io/clinTrialData/reference/list_available_studies.md)
  to see all options.

- repo:

  GitHub repository in the form `"owner/repo"`. Defaults to the official
  `clinTrialData` release repository.

## Value

Invisibly returns the metadata as a named list.

## Examples

``` r
if (FALSE) { # \dontrun{
dataset_info("cdisc_pilot_extended")
} # }
```
