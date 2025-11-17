# Package onLoad hook

Called when the package is loaded. Locks study folders if this is an
installed package (not in development mode). Also registers S3 methods
for connector integration.

## Usage

``` r
.onLoad(libname, pkgname)
```

## Arguments

- libname:

  Library name

- pkgname:

  Package name
