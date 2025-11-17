# List Available Clinical Data Sources

Returns information about all clinical datasets available in the
package.

## Usage

``` r
list_data_sources()
```

## Value

A data frame with columns: source, description, domains, format

## Examples

``` r
list_data_sources()
#>                 source          description    domains  format
#> 1          cdisc_pilot CDISC Pilot 01 Study adam, sdtm parquet
#> 2 cdisc_pilot_extended cdisc_pilot_extended adam, sdtm parquet
```
