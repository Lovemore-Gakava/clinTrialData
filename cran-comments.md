## Resubmission

This is a resubmission. The following issues raised by CRAN have been addressed:

* Added a reference (CDISC) in the Description field of DESCRIPTION with
  angle-bracket URL format.
* Removed examples from unexported internal functions `get_lock_status()` and
  `unlock_study()`.
* Replaced all `\dontrun{}` with `\donttest{}` for examples that download data
  (`download_study()`, `list_available_studies()`).

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
