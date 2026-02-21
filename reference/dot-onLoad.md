# Package onLoad hook

Called when the package is loaded. Registers bundled and cached study
folders as locked (in memory) to prevent accidental data modification.
No files are written to disk.

## Usage

``` r
.onLoad(libname, pkgname)
```

## Arguments

- libname:

  Library name

- pkgname:

  Package name
