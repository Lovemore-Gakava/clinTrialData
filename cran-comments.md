## Resubmission (0.1.3)

This is a resubmission fixing two issues flagged in the 0.1.2 pre-check.

### Hidden files NOTE (.claude/ directory)

The `.claude/` directory was inadvertently included in the tarball.
It has been added to `.Rbuildignore`.

### Possibly misspelled words NOTE (CDISC)

CDISC (Clinical Data Interchange Standards Consortium) is a proper acronym,
not a misspelling. It has been in `inst/WORDLIST` since the initial release.
`Language: en-US` has been added to DESCRIPTION so the spell checker
picks up the WORDLIST correctly.

---

## Background (archival reason — addressed in 0.1.2)

The package was archived because `lock_study()` called `Sys.chmod()` to set
cached study directories to mode 0555 (no write bit) on Unix, leaving
undeletable detritus in `~/.cache/R/clinTrialData/`. All `Sys.chmod()` calls
were removed in 0.1.2. The lock is now in-memory only via `.lock_env`.

## R CMD check results

0 errors | 0 warnings | 2 notes

- NOTE: "New submission / Package was archived on CRAN" — expected for a
  resubmission after archival.
- NOTE: "unable to verify current time" — local network issue; not
  reproducible on CRAN infrastructure.

## Test environments

* Windows 11 x64, R 4.5.2 (local)
* GitHub Actions: Ubuntu (latest), macOS (latest), Windows (latest)
