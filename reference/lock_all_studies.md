# Lock all study folders

Locks all study folders in the inst/exampledata directory. This is
typically called during package installation via .onLoad.

## Usage

``` r
lock_all_studies(base_path = "inst/exampledata", reason = "Package installed")
```

## Arguments

- base_path:

  Base path to the exampledata directory

- reason:

  Optional reason for the lock

## Value

Invisible list of locked folders
