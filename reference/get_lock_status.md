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

List with lock information or NULL if not locked

## Examples

``` r
if (FALSE) { # \dontrun{
# Check lock status
status <- get_lock_status("inst/exampledata/cdisc_pilot")
print(status)
} # }
```
