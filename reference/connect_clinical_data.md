# Connect to Clinical Data by Source

Generic connection function that allows access to any data source in the
package. Data sources are automatically discovered by scanning the
package's example data directory structure.

## Usage

``` r
connect_clinical_data(source = "cdisc_pilot")
```

## Arguments

- source:

  Character string specifying the data source. Use
  [`list_data_sources()`](https://lovemore-gakava.github.io/clinTrialData/reference/list_data_sources.md)
  to see all available options.

## Value

A `connectors` object

## Examples

``` r
# \donttest{
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

# List available datasets
db$adam$list_content_cnt()
#>  [1] "adae.parquet"     "adlb.parquet"     "adlbc.parquet"    "adlbh.parquet"   
#>  [5] "adlbhy.parquet"   "adqsadas.parquet" "adqscibc.parquet" "adqsnpix.parquet"
#>  [9] "adsl.parquet"     "adtte.parquet"    "advs.parquet"    

# Read a dataset
adsl <- db$adam$read_cnt("adsl")
#> → Found one file: /home/runner/work/_temp/Library/clinTrialData/exampledata/cdisc_pilot/adam/adsl.parquet

# List available sources
list_data_sources()
#>        source
#> 1 cdisc_pilot
#>                                                                                       description
#> 1 CDISC Pilot 01 Study — standard ADaM and SDTM datasets widely used for training and prototyping
#>      domains  format location
#> 1 adam, sdtm parquet  bundled
# }
```
