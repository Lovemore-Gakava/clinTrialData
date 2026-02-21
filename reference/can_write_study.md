# Check if a study folder can be written to

Returns TRUE if the folder is not locked; FALSE with a warning
otherwise.

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
