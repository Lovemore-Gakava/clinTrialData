# clinTrialData — TODO

## Open

### Design decisions (no code changes required)

**`%||%` operator**: Keep the internal definition or import from
`rlang`. Current approach avoids a dependency and works fine.

**`piggyback` in Suggests vs Imports**: Promoted to Imports.
[`list_available_studies()`](https://lovemore-gakava.github.io/clinTrialData/reference/list_available_studies.md)
and
[`download_study()`](https://lovemore-gakava.github.io/clinTrialData/reference/download_study.md)
now work out of the box without a separate install step.

### When needed

**[`list_data_sources()`](https://lovemore-gakava.github.io/clinTrialData/reference/list_data_sources.md)
description fallback**: Generate a minimal `metadata.json` during
[`download_study()`](https://lovemore-gakava.github.io/clinTrialData/reference/download_study.md)
when the zip doesn’t include one. Currently falls back to the folder
name.

**Reduce bundled data size**: The tarball is ~4 MB (4.9 MB installed).
Only act if CRAN flags it — bundled data could move to GitHub Releases
with `download_study("cdisc_pilot")` on first use.

**pkgdown site**: Verify `_pkgdown.yml` renders correctly after the
documentation changes.

## Completed

Replace `mockery` dependency with
[`testthat::local_mocked_bindings()`](https://testthat.r-lib.org/reference/local_mocked_bindings.html)

Remove `LazyData: false` from DESCRIPTION (no `data/` directory)

Rewrite lock system from file-based to in-memory (`R/lock.R`)

Remove PII ([`Sys.info()`](https://rdrr.io/r/base/Sys.info.html)
hostname/user) from lock metadata

Replace [`requireNamespace()`](https://rdrr.io/r/base/ns-load.html) with
mockable
[`has_package()`](https://lovemore-gakava.github.io/clinTrialData/reference/has_package.md)
wrapper

Fix `\dontrun` → `\donttest` for `dataset_info("cdisc_pilot")`

Fix ADLBURI documentation inaccuracy in `data.R` (not bundled)

Add missing bundled datasets to `data.R` docs

Make vignette execute bundled-data examples (`eval=TRUE`)

Convert [`cat()`](https://rdrr.io/r/base/cat.html) to
[`message()`](https://rdrr.io/r/base/message.html) in
`.print_dataset_info()`

Remove all non-ASCII characters from R source files

Fix README.Rmd: “10 ADaM” → “11 ADaM”, re-knit README.md

Add lock mechanism test suite (`test-lock.R`, 23 tests)

Refactor
[`list_data_sources()`](https://lovemore-gakava.github.io/clinTrialData/reference/list_data_sources.md)
to read descriptions from `metadata.json`

ASCII fallback for box-drawing characters in `.print_dataset_info()`

Add [`Sys.chmod()`](https://rdrr.io/r/base/files2.html) file-permission
hardening for cached studies (Unix)

Network test coverage for `download.R` via mockable wrappers

Test
[`dataset_info()`](https://lovemore-gakava.github.io/clinTrialData/reference/dataset_info.md)
local/bundled JSON parsing

Test
[`.set_permissions()`](https://lovemore-gakava.github.io/clinTrialData/reference/dot-set_permissions.md)
on Unix (skip on Windows)

Offline fallback for
[`list_available_studies()`](https://lovemore-gakava.github.io/clinTrialData/reference/list_available_studies.md)
