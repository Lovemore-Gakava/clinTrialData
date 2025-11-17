# Write Content with Lock Check

S3 method for write_cnt that checks if the study folder is locked before
allowing write operations.

## Usage

``` r
# S3 method for class 'ConnectorLockedFS'
write_cnt(connector_object, x, name, overwrite = FALSE, ...)
```

## Arguments

- connector_object:

  The ConnectorLockedFS object

- x:

  The data to write

- name:

  The file name

- overwrite:

  Whether to overwrite existing files

- ...:

  Additional arguments passed to the underlying connector

## Value

Invisible connector_object
