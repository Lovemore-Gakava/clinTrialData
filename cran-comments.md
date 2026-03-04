## Resubmission (0.1.1)

This is a resubmission addressing issues flagged in the CRAN check results for 0.1.0.

### Vignette ERROR on r-oldrel-macos-x86_64

The vignette failed to rebuild on platforms where the `arrow` package is not
available. All code chunks in `vignettes/getting-started.Rmd` that call
`read_cnt()` (which reads Parquet files via `arrow`) are now guarded with
`eval = requireNamespace("arrow", quietly = TRUE)` so they are silently skipped
when `arrow` is absent.

### donttest examples

The `\donttest{}` example for `connect_clinical_data()` called `read_cnt()`,
which requires `arrow`. The `read_cnt()` call is now wrapped in
`if (requireNamespace("arrow", quietly = TRUE))`.

### Package size NOTE

The installed size has been reduced from 5.4 MB to approximately 4.1 MB by
removing `adlb.parquet` from the bundled `cdisc_pilot` data. This file was a
derived dataset (created by row-binding `adlbc`, `adlbh`, and `adlbhy`) and is
not part of the original CDISC Pilot 01 source data. The three source datasets
are retained. The combined `adlb` dataset remains available in the
`cdisc_pilot_extended` study on GitHub Releases.

## R CMD check results

0 errors | 0 warnings | 0 notes

## Test environments

* Windows 11 x64, R 4.5.2 (local)
* GitHub Actions: Ubuntu (latest), macOS (latest), Windows (latest)
