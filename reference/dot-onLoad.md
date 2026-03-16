# Package onLoad hook

Called when the package is loaded. Registers bundled and cached study
folders as locked (in memory only) to prevent accidental data
modification. No files are written to disk and no file-system
permissions are changed.

## Usage

``` r
.onLoad(libname, pkgname)
```

## Arguments

- libname:

  Library name

- pkgname:

  Package name
