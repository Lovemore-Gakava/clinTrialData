# Unlock a study folder

Removes the lock file from a study folder, allowing it to be
overwritten.

## Usage

``` r
unlock_study(study_path)
```

## Arguments

- study_path:

  Path to the study folder

## Value

Logical indicating success

## Examples

``` r
if (FALSE) { # \dontrun{
# Unlock a study folder to allow regeneration
unlock_study("inst/exampledata/cdisc_pilot")
} # }
```
