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
  [`list_data_sources()`](https://lovemore-gakava.github.io/ctdata/reference/list_data_sources.md)
  to see all available options.

## Value

A `connectors` object

## Examples

``` r
if (FALSE) { # \dontrun{
# Connect to CDISC Pilot data
db <- connect_clinical_data("cdisc_pilot")

# List available datasets
db$adam$list_content_cnt()

# Read a dataset
adsl <- db$adam$read_cnt("adsl")

# List available sources
list_data_sources()
} # }
```
