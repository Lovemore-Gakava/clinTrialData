# Load a stale study listing and refresh the `cached` column

Load a stale study listing and refresh the `cached` column

## Usage

``` r
.load_stale_studies(reason)
```

## Arguments

- reason:

  Character string describing why the fallback is needed.

## Value

A data frame, or `NULL` if no cache exists.
