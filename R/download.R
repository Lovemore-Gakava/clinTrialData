#' Inspect a Clinical Trial Dataset Without Downloading
#'
#' @description
#' Fetches and displays metadata for any study available in the
#' `clinTrialData` library -- without downloading the full dataset. Metadata
#' includes the study description, available domains and datasets, subject
#' count, version, and data source attribution.
#'
#' For studies already downloaded via [download_study()], the metadata is read
#' from the local cache and works offline. For studies not yet downloaded, a
#' small JSON file (~2KB) is fetched from the GitHub Release.
#'
#' @param source Character string. Name of the study (e.g.
#'   `"cdisc_pilot_extended"`). Use [list_available_studies()] to see all
#'   options.
#' @param repo GitHub repository in the form `"owner/repo"`. Defaults to the
#'   official `clinTrialData` release repository.
#'
#' @return Invisibly returns the metadata as a named list.
#' @export
#'
#' @examples
#' \donttest{
#' dataset_info("cdisc_pilot")
#' }
dataset_info <- function(source, repo = "Lovemore-Gakava/clinTrialData") {
  meta <- NULL

  # 1. Try local cache first (works offline)
  cached_meta <- file.path(cache_dir(), source, "metadata.json")
  bundled_meta <- system.file(
    "exampledata", source, "metadata.json",
    package = "clinTrialData"
  )

  if (file.exists(cached_meta)) {
    meta <- jsonlite::fromJSON(cached_meta, simplifyVector = FALSE)
  } else if (!is.null(bundled_meta) && bundled_meta != "" && file.exists(bundled_meta)) {
    meta <- jsonlite::fromJSON(bundled_meta, simplifyVector = FALSE)
  } else {
    # 2. Fetch from GitHub Release

    releases <- tryCatch(
      .pb_releases(repo = repo),
      error = function(e) stop("Could not reach GitHub: ", conditionMessage(e))
    )
    if (nrow(releases) == 0) stop("No releases found in repo '", repo, "'.")

    # Find the release that has this study's metadata asset
    asset_name <- paste0(source, "_metadata.json")
    all_assets <- tryCatch(
      .pb_list(repo = repo),
      error = function(e) NULL
    )

    if (is.null(all_assets) || !asset_name %in% all_assets$file_name) {
      stop(
        "No metadata found for '", source, "'.\n",
        "The study may not exist, or metadata has not been generated yet.\n",
        "Use list_available_studies() to see all available studies."
      )
    }

    # Build direct download URL
    asset_row <- all_assets[all_assets$file_name == asset_name, ]
    asset_tag <- if ("tag" %in% names(asset_row)) asset_row$tag[[1]] else asset_row$tag_name[[1]]

    url <- sprintf(
      "https://github.com/%s/releases/download/%s/%s",
      repo, asset_tag, asset_name
    )

    # Use httr to handle redirects, fall back to utils::download.file
    raw <- tryCatch({
      resp <- .httr_get(url, httr::config(followlocation = TRUE))
      if (httr::status_code(resp) != 200) stop("HTTP ", httr::status_code(resp))
      httr::content(resp, as = "text", encoding = "UTF-8")
    }, error = function(e) {
      # Fallback: download to temp file
      tmp <- tempfile(fileext = ".json")
      on.exit(unlink(tmp))
      .download_file(url, tmp, quiet = TRUE, mode = "wb")
      readLines(tmp, warn = FALSE) |> paste(collapse = "\n")
    })

    meta <- tryCatch(
      jsonlite::fromJSON(raw, simplifyVector = FALSE),
      error = function(e) stop("Failed to parse metadata JSON: ", conditionMessage(e))
    )
  }

  .print_dataset_info(meta)
  invisible(meta)
}

#' @importFrom utils head
#' @keywords internal
.print_dataset_info <- function(meta) {
  source_name <- meta$source  %||% "unknown"
  version     <- meta$version %||% ""
  header <- if (nchar(version) > 0) {
    paste0(source_name, " (", version, ")")
  } else {
    source_name
  }

  sep_char <- if (l10n_info()[["UTF-8"]]) "\u2500" else "-"
  sep   <- strrep(sep_char, 70)
  lines <- character(0)

  lines <- c(lines, sep, header, sep)

  if (!is.null(meta$description)) {
    lines <- c(lines, meta$description, "")
  }


  if (!is.null(meta$domains) && length(meta$domains) > 0) {
    lines <- c(lines, "Domains & datasets:")
    for (domain in names(meta$domains)) {
      datasets <- unlist(meta$domains[[domain]])
      n        <- length(datasets)
      preview  <- paste(head(datasets, 8), collapse = ", ")
      if (n > 8) preview <- paste0(preview, ", ... (", n, " total)")
      lines <- c(lines, sprintf("  %-6s (%d): %s", domain, n, preview))
    }
    lines <- c(lines, "")
  }

  if (!is.null(meta$n_subjects)) lines <- c(lines, paste("Subjects:  ", meta$n_subjects))
  if (!is.null(meta$version))    lines <- c(lines, paste("Version:   ", meta$version))
  if (!is.null(meta$license))    lines <- c(lines, paste("License:   ", meta$license))
  if (!is.null(meta$source_url)) lines <- c(lines, paste("Source:    ", meta$source_url))
  lines <- c(lines, sep)

  message(paste(lines, collapse = "\n"))
}

#' @keywords internal
`%||%` <- function(x, y) if (is.null(x)) y else x

#' Check if a package is available
#'
#' Thin wrapper around [requireNamespace()] to allow mocking in tests.
#' @param pkg Package name.
#' @return Logical.
#' @keywords internal
has_package <- function(pkg) {
  requireNamespace(pkg, quietly = TRUE)
}

# Internal wrappers for external package calls.
# These exist solely so tests can use local_mocked_bindings() to intercept
# network calls without requiring httptest / httptest2 infrastructure.

#' @keywords internal
.pb_releases <- function(...) piggyback::pb_releases(...)

#' @keywords internal
.pb_list <- function(...) piggyback::pb_list(...)

#' @keywords internal
.pb_download <- function(...) piggyback::pb_download(...)

#' @keywords internal
.httr_get <- function(...) httr::GET(...)

#' @keywords internal
.download_file <- function(...) utils::download.file(...)

#' Path to the cached study-listing file
#'
#' Returns the path where [list_available_studies()] stores its last
#' successful result for offline fallback.
#' @keywords internal
.studies_cache_path <- function() {
  file.path(cache_dir(), ".studies_cache.rds")
}

#' Load a stale study listing and refresh the `cached` column
#'
#' @param reason Character string describing why the fallback is needed.
#' @return A data frame, or `NULL` if no cache exists.
#' @keywords internal
.load_stale_studies <- function(reason) {
  path <- .studies_cache_path()
  if (!file.exists(path)) return(NULL)

  stale <- tryCatch(readRDS(path), error = function(e) NULL)
  if (is.null(stale) || nrow(stale) == 0) return(NULL)

  # Recompute cached column from current filesystem
  cd <- cache_dir()
  stale$cached <- dir.exists(file.path(cd, stale$source))

  warning(
    reason, "\n",
    "Returning cached study list (may be out of date).",
    call. = FALSE
  )
  stale
}

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
#' When GitHub is unreachable, the function falls back to the last
#' successfully fetched listing (if available) and issues a warning.
#' The `cached` column is always recomputed from the local filesystem.
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
  releases <- tryCatch(
    .pb_releases(repo = repo),
    error = function(e) {
      # Try offline fallback before giving up
      stale <- .load_stale_studies(
        paste0("Could not fetch releases from GitHub repo '", repo, "'.")
      )
      if (!is.null(stale)) {
        attr(stale, "stale_fallback") <- TRUE
        return(stale)
      }

      stop(
        "Could not fetch releases from GitHub repo '", repo, "'.\n",
        "Check your internet connection and that the repo exists.\n",
        "Details: ", conditionMessage(e)
      )
    }
  )

  # If the fallback returned a stale study listing, pass it through directly
  if (isTRUE(attr(releases, "stale_fallback"))) return(releases)

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

  # Fetch all assets across all releases in one call
  all_assets <- tryCatch(
    .pb_list(repo = repo),
    error = function(e) NULL
  )

  if (is.null(all_assets) || nrow(all_assets) == 0) {
    # Try offline fallback
    stale <- .load_stale_studies("Could not fetch asset listing from GitHub.")
    if (!is.null(stale)) return(stale)

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

  # pb_list() returns column named "tag" (not "tag_name")
  version_col <- if ("tag" %in% names(zip_assets)) "tag" else "tag_name"

  # Check which are cached locally
  cd <- cache_dir()
  zip_assets$cached <- dir.exists(file.path(cd, zip_assets$source))

  result <- data.frame(
    source  = zip_assets$source,
    version = zip_assets[[version_col]],
    size_mb = zip_assets$size_mb,
    cached  = zip_assets$cached,
    stringsAsFactors = FALSE
  )

  # Cache the successful result for offline fallback
  tryCatch({
    dir.create(cache_dir(), recursive = TRUE, showWarnings = FALSE)
    saveRDS(result, .studies_cache_path())
  }, error = function(e) NULL)

  result
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
  used_latest <- version == "latest"
  if (used_latest) {
    releases <- tryCatch(
      .pb_releases(repo = repo),
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
    .pb_list(repo = repo),
    error = function(e) {
      stop("Could not list assets for release '", version, "': ",
           conditionMessage(e))
    }
  )

  # Filter to the requested version
  version_col <- if ("tag" %in% names(available)) "tag" else "tag_name"
  available <- available[available[[version_col]] == version, ]

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

  # Use "latest" tag string for pb_download when the caller asked for "latest"
  # — piggyback resolves it reliably, whereas an explicit tag can sometimes
  # cause pb_download() to return NULL
  dl_tag <- if (used_latest) "latest" else version

  .pb_download(
    file  = asset_name,
    dest  = tmp_dir,
    repo  = repo,
    tag   = dl_tag,
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
