#' Get the Local Cache Directory
#'
#' @description
#' Returns the path to the local cache directory where downloaded clinical
#' trial datasets are stored. The location follows the platform-specific
#' user data directory convention via [tools::R_user_dir()].
#'
#' You can delete any subdirectory here to remove a cached dataset, or clear
#' the entire directory to free disk space.
#'
#' @return A character string with the path to the cache directory.
#' @export
#'
#' @examples
#' cache_dir()
cache_dir <- function() {
  tools::R_user_dir("clinTrialData", "cache")
}

#' List Studies Available for Download
#'
#' @description
#' Returns a data frame of all clinical trial studies available as GitHub
#' Release assets, along with their local cache status. Studies marked as
#' `cached = TRUE` are already downloaded and available for use with
#' [connect_clinical_data()] without an internet connection.
#'
#' Requires the `piggyback` package.
#'
#' @param repo GitHub repository in the form `"owner/repo"`. Defaults to the
#'   official `clinTrialData` release repository.
#'
#' @return A data frame with columns:
#'   \describe{
#'     \item{source}{Study name (pass this to [download_study()] or
#'       [connect_clinical_data()])}
#'     \item{version}{Release tag the asset belongs to}
#'     \item{size_mb}{Asset size in megabytes}
#'     \item{cached}{`TRUE` if the study is already in the local cache}
#'   }
#' @export
#'
#' @examples
#' \dontrun{
#' list_available_studies()
#' }
list_available_studies <- function(repo = "Lovemore-Gakava/clinTrialData") {
  if (!requireNamespace("piggyback", quietly = TRUE)) {
    stop(
      "Package 'piggyback' is required to list available studies.\n",
      "Install it with: install.packages(\"piggyback\")"
    )
  }

  releases <- tryCatch(
    piggyback::pb_releases(repo = repo),
    error = function(e) {
      stop(
        "Could not fetch releases from GitHub repo '", repo, "'.\n",
        "Check your internet connection and that the repo exists.\n",
        "Details: ", conditionMessage(e)
      )
    }
  )

  if (nrow(releases) == 0) {
    message("No releases found in repo '", repo, "'.")
    return(data.frame(
      source  = character(0),
      version = character(0),
      size_mb = numeric(0),
      cached  = logical(0),
      stringsAsFactors = FALSE
    ))
  }

  # Fetch assets across all releases
  all_assets <- do.call(rbind, lapply(releases$tag_name, function(tag) {
    assets <- tryCatch(
      piggyback::pb_list(repo = repo, tag = tag),
      error = function(e) NULL
    )
    if (is.null(assets) || nrow(assets) == 0) return(NULL)
    assets$tag_name <- tag
    assets
  }))

  if (is.null(all_assets) || nrow(all_assets) == 0) {
    message("No dataset assets found in any release.")
    return(data.frame(
      source  = character(0),
      version = character(0),
      size_mb = numeric(0),
      cached  = logical(0),
      stringsAsFactors = FALSE
    ))
  }

  # Keep only .zip assets (one zip per study)
  zip_assets <- all_assets[grepl("\\.zip$", all_assets$file_name), ]

  if (nrow(zip_assets) == 0) {
    message("No .zip study assets found in releases.")
    return(data.frame(
      source  = character(0),
      version = character(0),
      size_mb = numeric(0),
      cached  = logical(0),
      stringsAsFactors = FALSE
    ))
  }

  # Derive study name from filename (e.g. "cdisc_pilot.zip" -> "cdisc_pilot")
  zip_assets$source <- sub("\\.zip$", "", zip_assets$file_name)
  zip_assets$size_mb <- round(zip_assets$size / 1024 / 1024, 1)

  # Check which are cached locally
  cd <- cache_dir()
  zip_assets$cached <- dir.exists(file.path(cd, zip_assets$source))

  data.frame(
    source  = zip_assets$source,
    version = zip_assets$tag_name,
    size_mb = zip_assets$size_mb,
    cached  = zip_assets$cached,
    stringsAsFactors = FALSE
  )
}

#' Download a Clinical Trial Study Dataset
#'
#' @description
#' Downloads a study dataset from a GitHub Release and stores it in the local
#' cache (see [cache_dir()]). Once downloaded, the study is available to
#' [connect_clinical_data()] without an internet connection.
#'
#' Requires the `piggyback` package.
#'
#' @param source Character string. The name of the study to download (e.g.
#'   `"cdisc_pilot"`). Use [list_available_studies()] to see all options.
#' @param version Character string. The release tag to download from. Defaults
#'   to `"latest"`, which resolves to the most recent release.
#' @param force Logical. If `TRUE`, re-download even if the study is already
#'   cached. Defaults to `FALSE`.
#' @param repo GitHub repository in the form `"owner/repo"`. Defaults to the
#'   official `clinTrialData` release repository.
#'
#' @return Invisibly returns the path to the cached study directory.
#' @export
#'
#' @examples
#' \dontrun{
#' # Download the CDISC Pilot study
#' download_study("cdisc_pilot")
#'
#' # Force re-download a specific version
#' download_study("cdisc_pilot", version = "v1.0.0", force = TRUE)
#'
#' # Then connect as usual
#' db <- connect_clinical_data("cdisc_pilot")
#' }
download_study <- function(source,
                           version = "latest",
                           force   = FALSE,
                           repo    = "Lovemore-Gakava/clinTrialData") {
  if (!requireNamespace("piggyback", quietly = TRUE)) {
    stop(
      "Package 'piggyback' is required to download studies.\n",
      "Install it with: install.packages(\"piggyback\")"
    )
  }

  cd <- cache_dir()
  study_cache_path <- file.path(cd, source)

  # Skip if already cached and not forcing
  if (dir.exists(study_cache_path) && !force) {
    message(
      "Study '", source, "' is already cached at:\n  ", study_cache_path,
      "\nUse force = TRUE to re-download."
    )
    return(invisible(study_cache_path))
  }

  # Resolve "latest" tag
  if (version == "latest") {
    releases <- tryCatch(
      piggyback::pb_releases(repo = repo),
      error = function(e) {
        stop(
          "Could not fetch releases from '", repo, "': ", conditionMessage(e)
        )
      }
    )
    if (nrow(releases) == 0) {
      stop("No releases found in repo '", repo, "'.")
    }
    version <- releases$tag_name[[1]]
  }

  asset_name <- paste0(source, ".zip")

  # Check the asset exists in this release
  available <- tryCatch(
    piggyback::pb_list(repo = repo, tag = version),
    error = function(e) {
      stop("Could not list assets for release '", version, "': ",
           conditionMessage(e))
    }
  )

  if (!asset_name %in% available$file_name) {
    stop(
      "Study '", source, "' not found in release '", version, "'.\n",
      "Available assets: ", paste(available$file_name, collapse = ", "), "\n",
      "Use list_available_studies() to see all options."
    )
  }

  # Download to a temp file then unzip into cache
  message("Downloading '", source, "' (", version, ") ...")
  tmp_dir  <- tempfile()
  dir.create(tmp_dir, recursive = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  piggyback::pb_download(
    file  = asset_name,
    dest  = tmp_dir,
    repo  = repo,
    tag   = version,
    overwrite = TRUE
  )

  zip_path <- file.path(tmp_dir, asset_name)

  if (!file.exists(zip_path)) {
    stop("Download appeared to succeed but zip file not found at: ", zip_path)
  }

  # Ensure cache dir exists
  dir.create(cd, recursive = TRUE, showWarnings = FALSE)

  # Remove old cached version if force = TRUE
  if (dir.exists(study_cache_path)) {
    unlink(study_cache_path, recursive = TRUE)
  }

  message("Extracting to cache ...")
  utils::unzip(zip_path, exdir = cd)

  if (!dir.exists(study_cache_path)) {
    stop(
      "Extraction did not produce expected directory: ", study_cache_path, "\n",
      "The zip may have a different internal structure."
    )
  }

  # Lock the downloaded study to prevent accidental writes
  lock_study(
    study_cache_path,
    reason = paste0("Downloaded from GitHub release ", version)
  )

  message("Done. '", source, "' is ready. Connect with:\n",
          "  connect_clinical_data(\"", source, "\")")

  invisible(study_cache_path)
}
