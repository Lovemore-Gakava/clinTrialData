# List Available Clinical Data Sources

Returns information about all clinical datasets available locally — both
datasets bundled with the package and any datasets previously downloaded
via
[`download_study()`](https://lovemore-gakava.github.io/clinTrialData/reference/download_study.md).
The `location` column indicates whether a dataset is `"bundled"`
(shipped with the package) or `"cached"` (downloaded to the user cache
directory).

To see datasets available for download from GitHub, use
[`list_available_studies()`](https://lovemore-gakava.github.io/clinTrialData/reference/list_available_studies.md).

## Usage

``` r
list_data_sources()
```

## Value

A data frame with columns:

- source:

  Dataset name (pass to
  [`connect_clinical_data()`](https://lovemore-gakava.github.io/clinTrialData/reference/connect_clinical_data.md))

- description:

  Human-readable study description

- domains:

  Comma-separated list of available data domains (e.g. `"adam, sdtm"`)

- format:

  Storage format (`"parquet"`)

- location:

  Either `"bundled"` or `"cached"`

## Examples

``` r
list_data_sources()
#>        source          description    domains  format location
#> 1 cdisc_pilot CDISC Pilot 01 Study adam, sdtm parquet  bundled
```
