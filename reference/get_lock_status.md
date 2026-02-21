# Get lock status for a study folder

Returns information about the lock status of a study folder.

## Usage

``` r
get_lock_status(study_path)
```

## Arguments

- study_path:

  Path to the study folder

## Value

A list with components `locked` (logical) and `path` (character).

## Examples

``` r
if (FALSE) { # \dontrun{
status <- get_lock_status("inst/exampledata/cdisc_pilot")
status$locked
} # }
```
