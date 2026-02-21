# Lock a study folder

Marks a study path as locked for the duration of the current R session.
On Unix-like systems, cached study directories are also made read-only
at the file-system level via
[`Sys.chmod()`](https://rdrr.io/r/base/files2.html).

## Usage

``` r
lock_study(study_path, reason = "Package installed")
```

## Arguments

- study_path:

  Path to the study folder

- reason:

  Optional reason for the lock (included in messages only)

## Value

Logical indicating success, invisibly
