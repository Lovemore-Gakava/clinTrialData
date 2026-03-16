# Lock a study folder

Marks a study path as locked for the duration of the current R session.
The lock is in-memory only: no file-system permissions are modified.

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
