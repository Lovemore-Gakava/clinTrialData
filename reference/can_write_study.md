# Check if study folder should be written

Helper function to check if a study folder can be safely written to.
Returns TRUE if the folder can be written, FALSE if it's locked. Issues
a warning if the folder is locked.

## Usage

``` r
can_write_study(study_path, operation = "write to study folder")
```

## Arguments

- study_path:

  Path to the study folder

- operation:

  Description of the operation being attempted

## Value

Logical indicating if the operation can proceed
