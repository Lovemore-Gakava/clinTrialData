# Generate Connector Configuration from Directory Structure

Scans a data source directory and generates a connector configuration
list dynamically based on the available parquet files.

## Usage

``` r
generate_connector_config(source_path)
```

## Arguments

- source_path:

  Path to the data source directory

## Value

A list suitable for passing to connector::connect()
