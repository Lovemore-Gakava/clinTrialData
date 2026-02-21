# clinTrialData — TODO

## Open

### Design decisions (no code changes required)

- [ ] **`%||%` operator**: Keep the internal definition or import from
  `rlang`. Current approach avoids a dependency and works fine.

- [x] **`piggyback` in Suggests vs Imports**: Promoted to Imports.
  `list_available_studies()` and `download_study()` now work out of the
  box without a separate install step.

### When needed

- [ ] **`list_data_sources()` description fallback**: Generate a minimal
  `metadata.json` during `download_study()` when the zip doesn't include
  one. Currently falls back to the folder name.

- [ ] **Reduce bundled data size**: The tarball is ~4 MB (4.9 MB
  installed). Only act if CRAN flags it — bundled data could move to
  GitHub Releases with `download_study("cdisc_pilot")` on first use.

- [ ] **pkgdown site**: Verify `_pkgdown.yml` renders correctly after the
  documentation changes.

## Completed

- [x] Replace `mockery` dependency with `testthat::local_mocked_bindings()`
- [x] Remove `LazyData: false` from DESCRIPTION (no `data/` directory)
- [x] Rewrite lock system from file-based to in-memory (`R/lock.R`)
- [x] Remove PII (`Sys.info()` hostname/user) from lock metadata
- [x] Replace `requireNamespace()` with mockable `has_package()` wrapper
- [x] Fix `\dontrun` → `\donttest` for `dataset_info("cdisc_pilot")`
- [x] Fix ADLBURI documentation inaccuracy in `data.R` (not bundled)
- [x] Add missing bundled datasets to `data.R` docs
- [x] Make vignette execute bundled-data examples (`eval=TRUE`)
- [x] Convert `cat()` to `message()` in `.print_dataset_info()`
- [x] Remove all non-ASCII characters from R source files
- [x] Fix README.Rmd: "10 ADaM" → "11 ADaM", re-knit README.md
- [x] Add lock mechanism test suite (`test-lock.R`, 23 tests)
- [x] Refactor `list_data_sources()` to read descriptions from `metadata.json`
- [x] ASCII fallback for box-drawing characters in `.print_dataset_info()`
- [x] Add `Sys.chmod()` file-permission hardening for cached studies (Unix)
- [x] Network test coverage for `download.R` via mockable wrappers
- [x] Test `dataset_info()` local/bundled JSON parsing
- [x] Test `.set_permissions()` on Unix (skip on Windows)
- [x] Offline fallback for `list_available_studies()`
