# Unlock a study folder

Removes the in-memory lock on a study path, allowing write operations
for the remainder of the current R session. On Unix-like systems, also
restores write permissions on cached study directories.

## Usage

``` r
unlock_study(study_path)
```

## Arguments

- study_path:

  Path to the study folder

## Value

Logical indicating success, invisibly
