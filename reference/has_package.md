# Check if a package is available

Thin wrapper around
[`requireNamespace()`](https://rdrr.io/r/base/ns-load.html) to allow
mocking in tests.

## Usage

``` r
has_package(pkg)
```

## Arguments

- pkg:

  Package name.

## Value

Logical.
