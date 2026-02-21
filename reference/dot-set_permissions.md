# Set directory permissions (Unix only)

On Unix-like systems, sets the directory and its files to read-only
(mode 0555/0444) or read-write (mode 0755/0644). This is a no-op on
Windows, where these permission bits are not meaningful. Only applied to
paths under the user cache directory.

## Usage

``` r
.set_permissions(path, read_only = TRUE)
```

## Arguments

- path:

  Directory path.

- read_only:

  Logical; TRUE to make read-only, FALSE to restore.
