# Create a lock file for a study folder

Creates a lock file to prevent overwriting of a study folder. This is
typically called after package installation to protect the installed
data from being overwritten by data-raw scripts.

## Usage

``` r
lock_study(study_path, reason = "Package installed")
```

## Arguments

- study_path:

  Path to the study folder

- reason:

  Optional reason for the lock (default: "Package installed")

## Value

Logical indicating success
