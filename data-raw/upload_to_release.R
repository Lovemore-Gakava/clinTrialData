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
DATA_DIR   <- file.path(getwd(), "inst", "exampledata")

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

# -----------------------------------------------------------------------------
#' Generate metadata.json for a study folder
#'
#' Scans a study's parquet files to auto-detect domains, dataset names, and
#' subject count. Writes metadata.json into the study folder and returns the
#' metadata list invisibly.
#'
#' @param source        Name of the study folder (inside DATA_DIR)
#' @param description   Human-readable description of the study
#' @param version       Release tag string (e.g. "v0.1.0")
#' @param license       License / usage note for the data
#' @param source_url    URL to the original data source
#' @param data_dir      Path to the directory containing the study folder
generate_metadata <- function(source,
                              description = "",
                              version     = "v0.1.0",
                              license     = "",
                              source_url  = "",
                              data_dir    = DATA_DIR) {
  if (!requireNamespace("arrow",     quietly = TRUE)) stop("Package 'arrow' required.")
  if (!requireNamespace("jsonlite",  quietly = TRUE)) stop("Package 'jsonlite' required.")

  study_path <- file.path(data_dir, source)
  if (!dir.exists(study_path)) stop("Study folder not found: ", study_path)

  # Discover domains (subdirs with parquet files)
  domain_dirs <- list.dirs(study_path, recursive = FALSE, full.names = FALSE)
  domain_dirs <- domain_dirs[domain_dirs != ""]

  domains      <- list()
  all_subjects <- character(0)

  for (domain in domain_dirs) {
    parquet_files <- list.files(
      file.path(study_path, domain),
      pattern = "\\.parquet$",
      full.names = FALSE
    )
    if (length(parquet_files) == 0) next

    dataset_names <- sub("\\.parquet$", "", parquet_files)
    domains[[domain]] <- as.list(dataset_names)

    # Try to read USUBJID from the first parquet to get subject count
    if (length(all_subjects) == 0) {
      tryCatch({
        first_file <- file.path(study_path, domain, parquet_files[[1]])
        df <- arrow::read_parquet(first_file, col_select = "USUBJID")
        all_subjects <- unique(df$USUBJID)
      }, error = function(e) NULL)
    }
  }

  meta <- list(
    source      = source,
    description = description,
    domains     = domains,
    n_subjects  = length(all_subjects),
    version     = version,
    license     = license,
    source_url  = source_url
  )

  out_path <- file.path(study_path, "metadata.json")
  jsonlite::write_json(meta, out_path, pretty = TRUE, auto_unbox = TRUE)
  message("Written: ", out_path)

  invisible(meta)
}

# -----------------------------------------------------------------------------
#' Generate metadata and upload it as a release asset
#'
#' Convenience wrapper: generates metadata.json, then uploads it to the
#' GitHub Release as `<source>_metadata.json`.
#'
#' @param source      Name of the study folder
#' @param description Human-readable study description
#' @param version     Release tag (e.g. "v0.1.0")
#' @param license     License / usage note
#' @param source_url  URL to original data
#' @param tag         Release tag to upload to (defaults to version)
#' @param repo        GitHub repo
#' @param data_dir    Path containing the study folder
generate_and_upload_metadata <- function(source,
                                         description = "",
                                         version     = "v0.1.0",
                                         license     = "",
                                         source_url  = "",
                                         tag         = version,
                                         repo        = REPO,
                                         data_dir    = DATA_DIR) {
  meta <- generate_metadata(
    source      = source,
    description = description,
    version     = version,
    license     = license,
    source_url  = source_url,
    data_dir    = data_dir
  )

  json_path  <- file.path(data_dir, source, "metadata.json")
  asset_name <- paste0(source, "_metadata.json")

  message("Uploading '", asset_name, "' to release '", tag, "' ...")
  piggyback::pb_upload(
    file      = json_path,
    repo      = repo,
    tag       = tag,
    name      = asset_name,
    overwrite = TRUE
  )
  message("Done: metadata for '", source, "' uploaded to ", repo, "@", tag)

  invisible(meta)
}

# =============================================================================
# Example workflow — uncomment and run interactively:
# =============================================================================
#
# # 1. Create a new release (only needed once per version)
# piggyback::pb_new_release(repo = REPO, tag = "v1.0.0")
#
# # 2. Upload all current studies + their metadata
# upload_all_studies(tag = "v1.0.0")
#
# generate_and_upload_metadata(
#   source      = "cdisc_pilot",
#   description = "CDISC Pilot 01 Study",
#   version     = "v1.0.0",
#   license     = "CDISC Pilot — educational use",
#   source_url  = "https://github.com/cdisc-org/sdtm-adam-pilot-project",
#   tag         = "v1.0.0"
# )
#
# # 3. Add a new study contributed by the community:
# #    - Organise parquet files in a folder: your_study/adam/, your_study/sdtm/
# #    - Then upload zip + metadata:
# upload_study_to_release("your_study", tag = "v1.0.0")
# generate_and_upload_metadata(
#   source      = "your_study",
#   description = "Brief description of your study",
#   version     = "v1.0.0",
#   license     = "Your license here",
#   source_url  = "https://link-to-original-data",
#   tag         = "v1.0.0"
# )
# # Users can now access it immediately — no CRAN resubmission needed!
