## Resubmission

This is a resubmission. The following issue raised by CRAN has been addressed:

* Fixed invalid URL in `README.md`: `https://github.com/pharmaverse/connector`
  has been corrected to `https://github.com/NovoNordisk-OpenSource/connector`,
  which is the actual GitHub repository for the 'connector' package on CRAN.

## R CMD check results

0 errors | 0 warnings | 0 notes

## Package size

The installed package size is 5.4 MB (4.9 MB in `inst/exampledata/`). This
directory contains the CDISC Pilot 01 study in Parquet format — a widely-used
standard reference dataset for clinical data analysis training and prototyping.
It is bundled so the package works fully offline without a network call.
Additional datasets are hosted on GitHub Releases and downloaded on demand via
`download_study()`.

## Test environments

* Windows 11 x64, R 4.5.2 (local)
* GitHub Actions: Ubuntu (latest), macOS (latest), Windows (latest)
