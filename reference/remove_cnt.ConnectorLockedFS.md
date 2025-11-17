# Remove Content with Lock Check

S3 method for remove_cnt that checks if the study folder is locked
before allowing remove operations.

## Usage

``` r
# S3 method for class 'ConnectorLockedFS'
remove_cnt(connector_object, name, ...)
```

## Arguments

- connector_object:

  The ConnectorLockedFS object

- name:

  The file name to remove

- ...:

  Additional arguments passed to the underlying connector

## Value

Invisible connector_object
