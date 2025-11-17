# Connect to Data Source

Generic function to connect to any data source by scanning its directory
structure and generating the connector configuration dynamically. Wraps
all filesystem connectors with lock protection.

## Usage

``` r
connect_to_source(source_name)
```

## Arguments

- source_name:

  Name of the data source (e.g., "cdisc_pilot")

## Value

A `connectors` object
