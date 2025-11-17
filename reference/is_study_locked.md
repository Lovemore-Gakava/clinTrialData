# Check if a study folder is locked

Checks if a lock file exists for a study folder, indicating that the
folder should not be overwritten (typically because the package has been
installed).

## Usage

``` r
is_study_locked(study_path)
```

## Arguments

- study_path:

  Path to the study folder

## Value

Logical indicating if the folder is locked
