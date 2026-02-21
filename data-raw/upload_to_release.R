# =============================================================================
# upload_to_release.R
#
# Maintainer script: zip up one or more study folders from inst/exampledata/
# and upload them as assets to a GitHub Release using piggyback.
#
# Prerequisites:
#   install.packages("piggyback")
#
# Authentication:
#   Set a GitHub PAT with repo scope before running:
#   Sys.setenv(GITHUB_PAT = "ghp_...")
#   Or use: gitcreds::gitcreds_set()
#
# Usage:
#   # Upload a single study to the latest release:
#   upload_study_to_release("cdisc_pilot", tag = "v1.0.0")
#
#   # Upload all studies at once:
#   upload_all_studies(tag = "v1.0.0")
#
#   # Create the release first if it doesn't exist:
#   piggyback::pb_new_release(repo = REPO, tag = "v1.0.0")
# =============================================================================

library(piggyback)

REPO       <- "Lovemore-Gakava/clinTrialData"
DATA_DIR   <- here::here("inst", "exampledata")  # adjust if running from elsewhere

# -----------------------------------------------------------------------------
#' Upload a single study folder as a zip asset to a GitHub Release
#'
#' @param source   Name of the study folder inside inst/exampledata/
#' @param tag      Release tag (e.g. "v1.0.0")
#' @param repo     GitHub repo (owner/name)
#' @param overwrite Whether to overwrite an existing asset of the same name
upload_study_to_release <- function(source,
                                    tag       = "latest",
                                    repo      = REPO,
                                    overwrite = TRUE) {
  study_path <- file.path(DATA_DIR, source)

  if (!dir.exists(study_path)) {
    stop("Study folder not found: ", study_path)
  }

  # Resolve "latest" tag
  if (tag == "latest") {
    releases <- piggyback::pb_releases(repo = repo)
    if (nrow(releases) == 0) stop("No releases found. Create one first with pb_new_release().")
    tag <- releases$tag_name[[1]]
    message("Resolved 'latest' to tag: ", tag)
  }

  zip_name <- paste0(source, ".zip")
  tmp_zip  <- file.path(tempdir(), zip_name)
  on.exit(unlink(tmp_zip), add = TRUE)

  message("Zipping '", source, "' ...")
  # zip() paths are relative to the working directory, so set wd temporarily
  old_wd <- setwd(DATA_DIR)
  on.exit(setwd(old_wd), add = TRUE)

  zip_result <- utils::zip(
    zipfile = tmp_zip,
    files   = source,
    flags   = "-r9X"  # recursive, max compression, no extra attributes
  )

  setwd(old_wd)
  on.exit(setwd(old_wd), add = FALSE)  # already restored

  if (!file.exists(tmp_zip)) stop("Zip creation failed for: ", source)

  size_mb <- round(file.size(tmp_zip) / 1024 / 1024, 1)
  message("Uploading '", zip_name, "' (", size_mb, " MB) to release '", tag, "' ...")

  piggyback::pb_upload(
    file      = tmp_zip,
    repo      = repo,
    tag       = tag,
    name      = zip_name,
    overwrite = overwrite
  )

  message("Done: '", source, "' uploaded to ", repo, "@", tag)
  invisible(zip_name)
}

# -----------------------------------------------------------------------------
#' Upload all studies in inst/exampledata/ to a GitHub Release
#'
#' @param tag       Release tag (e.g. "v1.0.0")
#' @param repo      GitHub repo (owner/name)
#' @param overwrite Whether to overwrite existing assets
upload_all_studies <- function(tag       = "latest",
                               repo      = REPO,
                               overwrite = TRUE) {
  studies <- list.dirs(DATA_DIR, recursive = FALSE, full.names = FALSE)
  studies <- studies[studies != ""]

  if (length(studies) == 0) stop("No study folders found in: ", DATA_DIR)

  message("Found ", length(studies), " studies to upload: ",
          paste(studies, collapse = ", "))

  for (study in studies) {
    tryCatch(
      upload_study_to_release(study, tag = tag, repo = repo, overwrite = overwrite),
      error = function(e) {
        warning("Failed to upload '", study, "': ", conditionMessage(e))
      }
    )
  }

  message("\nAll studies processed.")
}

# =============================================================================
# Example workflow — uncomment and run interactively:
# =============================================================================
#
# # 1. Create a new release (only needed once per version)
# piggyback::pb_new_release(repo = REPO, tag = "v1.0.0")
#
# # 2. Upload all current studies
# upload_all_studies(tag = "v1.0.0")
#
# # 3. Later, add a new study without a new release:
# #    - Add parquet files to inst/exampledata/new_study/
# #    - Then:
# upload_study_to_release("new_study", tag = "v1.0.0")
# # No CRAN resubmission needed!
