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

### Downloadable studies (GitHub Release assets)

**Every new release tag must carry *all* studies’ assets**:
`download_study(version = "latest")` resolves to the newest release and
then filters the asset list to that release only, so a tag that ships
one study breaks
[`download_study()`](https://lovemore-gakava.github.io/clinTrialData/reference/download_study.md)
for the others. `v0.1.1` and `v0.1.2` both re-carry the full set of six
assets. Worth making `upload_all_studies()` the documented default, or
having
[`download_study()`](https://lovemore-gakava.github.io/clinTrialData/reference/download_study.md)
fall back to searching older releases.

**`onco_phase3_solid` ADaM labels (upstream dependency)**: ADaM datasets
were largely unlabelled – 107/333 columns (32%). Five were fully
unlabelled: `adex`, `adlb`, `adrs`, `adtr`, `adtte`. Root cause was
upstream in the source ADaM derivation, tracked at
[OpenTrialReporting/torivumab-nsclc-301#14](https://github.com/OpenTrialReporting/torivumab-nsclc-301/issues/14).
**Resolved 2026-07-18**: fixed upstream (source `d189351`, ADaM now
333/333). `onco_phase3_solid.zip` rebuilt and re-uploaded to the
`v0.1.0` release; verified 333/333 (100%) from the published asset. SDTM
unchanged at 268/282 (`suppsu` still 0/10 – out of scope of \#14).

**`onco_phase3_solid` P21-remediation reload (was HELD)**: The published
asset was built from `d189351`, while the source kept moving through
Pinnacle 21 remediation, so it went stale. **Decision 2026-07-18: hold
the reload** until a clean/dispositioned P21 run. **Released 2026-07-26
as `v0.1.2`** (source `a427d6c`): P21 is now dispositioned – SDTM 10,891
/ ADaM 10,890 findings, of which 10,873 are the single accepted `SD0007`
DA-units warning and the remainder are documented accepted limitations.
The bundle also grew from 22 to **26 SDTM domains** (adds trial design
`ts`/`ta`/`te`/`se`), gained SAP §12.2 date-based analysis-visit
windowing with a unified `ANL01FL`, an ALP analyte and unscheduled
lab/vitals visits. Verified from the published URL: 38/38 Parquet
re-read, 812,681 rows, **708/708 variables labelled** (`suppsu` now
labelled too), ADSL/DM both 450 subjects. Metadata description corrected
to the true **1:1 (225:225)** allocation – earlier text said 2:1, copied
from the source protocol synopsis.

## Completed

Derive `n_subjects` from ADSL/DM in `data-raw/upload_to_release.R`
(previously read the first alphabetical file, `adae`, undercounting
subjects with no adverse event)

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

Test `.set_permissions()` on Unix (skip on Windows)

Offline fallback for
[`list_available_studies()`](https://lovemore-gakava.github.io/clinTrialData/reference/list_available_studies.md)
