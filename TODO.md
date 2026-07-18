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

### Downloadable studies (GitHub Release assets)

- [x] **`onco_phase3_solid` ADaM labels (upstream dependency)**: ADaM datasets
  were largely unlabelled -- 107/333 columns (32%). Five were fully unlabelled:
  `adex`, `adlb`, `adrs`, `adtr`, `adtte`. Root cause was upstream in the source
  ADaM derivation, tracked at
  [OpenTrialReporting/torivumab-nsclc-301#14](https://github.com/OpenTrialReporting/torivumab-nsclc-301/issues/14).
  **Resolved 2026-07-18**: fixed upstream (source `d189351`, ADaM now 333/333).
  `onco_phase3_solid.zip` rebuilt and re-uploaded to the `v0.1.0` release;
  verified 333/333 (100%) from the published asset. SDTM unchanged at 268/282
  (`suppsu` still 0/10 -- out of scope of #14).

- [ ] **`onco_phase3_solid` P21-remediation reload (HELD)**: Source has advanced
  past the published bundle -- published asset was built from `d189351`; source
  is now at `d5d738f` with Pinnacle 21 remediation **in progress** (e.g.
  `AVISIT`/`AVISITN` added to 5 BDS datasets; baseline/PARAM/flag/study-day
  content fixes), so the release asset is stale. P21 reports (SDTM-IG 3.4 +
  ADaM-IG 1.3, Community 4.1.0) uploaded upstream at
  `qc/p21-reports/2026-07-18/`. Open items in those reports include ADaM
  derivation defects (`AD0154` multiple baseline, `AD0152` `ABLFL`/`BASE`,
  `AD0196` null `PARAMCD`, `AD0141` `PARAM`, `SD1152` duplicates) and 68
  `AD0018` label-text mismatches; CT findings (`CT2001/2/3`) are accepted
  synthetic-data limitations. **Decision 2026-07-18: hold the reload** until a
  clean/dispositioned P21 run, then rebuild `onco_phase3_solid.zip`, re-upload
  to `v0.1.0`, and re-verify (coverage + labels).

## Completed

- [x] Derive `n_subjects` from ADSL/DM in `data-raw/upload_to_release.R`
  (previously read the first alphabetical file, `adae`, undercounting
  subjects with no adverse event)
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
