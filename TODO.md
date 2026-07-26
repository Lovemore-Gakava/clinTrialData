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

- [ ] **Every new release tag must carry *all* studies' assets**:
  `download_study(version = "latest")` resolves to the newest release and then
  filters the asset list to that release only, so a tag that ships one study
  breaks `download_study()` for the others. `v0.1.1` and `v0.1.2` both re-carry
  the full set of six assets. Worth making `upload_all_studies()` the documented
  default, or having `download_study()` fall back to searching older releases.

- [x] **`onco_phase3_solid` ADaM labels (upstream dependency)**: ADaM datasets
  were largely unlabelled -- 107/333 columns (32%). Five were fully unlabelled:
  `adex`, `adlb`, `adrs`, `adtr`, `adtte`. Root cause was upstream in the source
  ADaM derivation, tracked at
  [OpenTrialReporting/torivumab-nsclc-301#14](https://github.com/OpenTrialReporting/torivumab-nsclc-301/issues/14).
  **Resolved 2026-07-18**: fixed upstream (source `d189351`, ADaM now 333/333).
  `onco_phase3_solid.zip` rebuilt and re-uploaded to the `v0.1.0` release;
  verified 333/333 (100%) from the published asset. SDTM unchanged at 268/282
  (`suppsu` still 0/10 -- out of scope of #14).

- [x] **`onco_phase3_solid` P21-remediation reload (was HELD)**: The published
  asset was built from `d189351`, while the source kept moving through Pinnacle
  21 remediation, so it went stale. **Decision 2026-07-18: hold the reload**
  until a clean/dispositioned P21 run. **Released 2026-07-26 as `v0.1.2`**
  (source `a427d6c`): P21 is now dispositioned -- SDTM 10,891 / ADaM 10,890
  findings, of which 10,873 are the single accepted `SD0007` DA-units warning
  and the remainder are documented accepted limitations. The bundle also grew
  from 22 to **26 SDTM domains** (adds trial design `ts`/`ta`/`te`/`se`), gained
  SAP §12.2 date-based analysis-visit windowing with a unified `ANL01FL`, an ALP
  analyte and unscheduled lab/vitals visits. Verified from the published URL:
  38/38 Parquet re-read, 812,681 rows, **708/708 variables labelled** (`suppsu`
  now labelled too), ADSL/DM both 450 subjects. Metadata description corrected
  to the true **1:1 (225:225)** allocation -- earlier text said 2:1, copied from
  the source protocol synopsis.

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
