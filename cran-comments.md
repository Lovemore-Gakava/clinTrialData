## Resubmission (0.1.2)

This is a resubmission following archival of 0.1.1.

### Archival reason addressed

The package was archived because `lock_study()` called `Sys.chmod()` to set
cached study directories to mode 0555 (no write bit) on Unix. This left
undeletable detritus in `~/.cache/R/clinTrialData/` after R sessions ended,
blocking cleanup by the account that ran the CRAN checks.

The fix removes all filesystem permission changes. The in-memory lock
(`.lock_env`) is sufficient to guard against accidental overwrites within a
session. No `Sys.chmod()` calls remain in the package.

## R CMD check results

0 errors | 0 warnings | 2 notes

* NOTE: "New submission / Package was archived on CRAN" — expected for a
  resubmission after archival.
* NOTE: "unable to verify current time" — local network issue; not reproducible
  on CRAN infrastructure.

## Test environments

* Windows 11 x64, R 4.5.2 (local)
* GitHub Actions: Ubuntu (latest), macOS (latest), Windows (latest)
