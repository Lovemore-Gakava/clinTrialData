# Get the Local Cache Directory

Returns the path to the local cache directory where downloaded clinical
trial datasets are stored. The location follows the platform-specific
user data directory convention via
[`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html).

You can delete any subdirectory here to remove a cached dataset, or
clear the entire directory to free disk space.

## Usage

``` r
cache_dir()
```

## Value

A character string with the path to the cache directory.

## Examples

``` r
cache_dir()
#> [1] "/home/runner/.cache/R/clinTrialData"
```
