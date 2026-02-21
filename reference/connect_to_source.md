# Connect to Data Source

Generic function to connect to any data source by scanning its directory
structure and generating the connector configuration dynamically. Wraps
all filesystem connectors with lock protection.

Resolution order:

1.  User cache (downloaded via
    [`download_study()`](https://lovemore-gakava.github.io/clinTrialData/reference/download_study.md))

2.  Package-bundled data (`inst/exampledata/`)

## Usage

``` r
connect_to_source(source_name)
```

## Arguments

- source_name:

  Name of the data source (e.g., "cdisc_pilot")

## Value

A `connectors` object
