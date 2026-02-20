# Package-level environment for in-memory lock tracking.
# Populated at load time; no files are written to the installation directory.
.lock_env <- new.env(parent = emptyenv())
.lock_env$locked_paths <- character(0)

#' Set directory permissions (Unix only)
#'
#' On Unix-like systems, sets the directory and its files to read-only
#' (mode 0555/0444) or read-write (mode 0755/0644). This is a no-op
#' on Windows, where these permission bits are not meaningful.
#' Only applied to paths under the user cache directory.
#'
#' @param path Directory path.
#' @param read_only Logical; TRUE to make read-only, FALSE to restore.
#' @keywords internal
.set_permissions <- function(path, read_only = TRUE) {
  if (.Platform$OS.type != "unix") return(invisible(NULL))

 # Only harden paths under the user cache, not the installed package
  cache_root <- normalizePath(
    tools::R_user_dir("clinTrialData", "cache"),
    mustWork = FALSE
  )
  norm_path <- normalizePath(path, mustWork = FALSE)
  if (!startsWith(norm_path, cache_root)) return(invisible(NULL))

  if (!dir.exists(path)) return(invisible(NULL))

  if (read_only) {
    # Files read-only, dirs read + execute (to allow listing)
    files <- list.files(path, recursive = TRUE, full.names = TRUE)
    for (f in files) Sys.chmod(f, "0444")
    dirs <- list.dirs(path, recursive = TRUE, full.names = TRUE)
    for (d in dirs) Sys.chmod(d, "0555")
  } else {
    # Restore write permissions
    dirs <- list.dirs(path, recursive = TRUE, full.names = TRUE)
    for (d in dirs) Sys.chmod(d, "0755")
    files <- list.files(path, recursive = TRUE, full.names = TRUE)
    for (f in files) Sys.chmod(f, "0644")
  }

  invisible(NULL)
}

#' Check if a study folder is locked
#'
#' @description
#' Checks whether a study path is locked in the current session, indicating
#' that the data should not be overwritten.
#'
#' @param study_path Path to the study folder
#' @return Logical indicating if the folder is locked
#' @keywords internal
is_study_locked <- function(study_path) {
  normalizePath(study_path, mustWork = FALSE) %in% .lock_env$locked_paths
}

#' Lock a study folder
#'
#' @description
#' Marks a study path as locked for the duration of the current R session.
#' On Unix-like systems, cached study directories are also made read-only
#' at the file-system level via `Sys.chmod()`.
#'
#' @param study_path Path to the study folder
#' @param reason Optional reason for the lock (included in messages only)
#' @return Logical indicating success, invisibly
#' @keywords internal
lock_study <- function(study_path, reason = "Package installed") {
  if (!dir.exists(study_path)) {
    warning("Study folder does not exist: ", study_path)
    return(invisible(FALSE))
  }

  np <- normalizePath(study_path, mustWork = FALSE)
  if (!np %in% .lock_env$locked_paths) {
    .lock_env$locked_paths <- c(.lock_env$locked_paths, np)
  }

  # Harden file permissions on cached studies (Unix only)
  .set_permissions(study_path, read_only = TRUE)

  invisible(TRUE)
}

#' Unlock a study folder
#'
#' @description
#' Removes the in-memory lock on a study path, allowing write operations
#' for the remainder of the current R session. On Unix-like systems, also
#' restores write permissions on cached study directories.
#'
#' @param study_path Path to the study folder
#' @return Logical indicating success, invisibly
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' # Unlock a study folder to allow regeneration
#' unlock_study("inst/exampledata/cdisc_pilot")
#' }
unlock_study <- function(study_path) {
  np <- normalizePath(study_path, mustWork = FALSE)
  .lock_env$locked_paths <- setdiff(.lock_env$locked_paths, np)

  # Restore write permissions (Unix only, cache paths only)
  .set_permissions(study_path, read_only = FALSE)

  invisible(TRUE)
}

#' Lock all study folders
#'
#' @description
#' Locks all study folders under a base path (in-memory).
#'
#' @param base_path Base path to the exampledata directory
#' @param reason Optional reason for the lock
#' @return Invisible character vector of locked folder paths
#' @keywords internal
lock_all_studies <- function(
    base_path = "inst/exampledata",
    reason = "Package installed") {
  if (!dir.exists(base_path)) {
    return(invisible(character(0)))
  }

  study_folders <- list.dirs(base_path, recursive = FALSE, full.names = TRUE)

  for (folder in study_folders) {
    lock_study(folder, reason)
  }

  invisible(study_folders)
}

#' Get lock status for a study folder
#'
#' @description
#' Returns information about the lock status of a study folder.
#'
#' @param study_path Path to the study folder
#' @return A list with components `locked` (logical) and `path` (character).
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' status <- get_lock_status("inst/exampledata/cdisc_pilot")
#' status$locked
#' }
get_lock_status <- function(study_path) {
  list(
    locked = is_study_locked(study_path),
    path = study_path
  )
}

#' Check if a study folder can be written to
#'
#' @description
#' Returns TRUE if the folder is not locked; FALSE with a warning otherwise.
#'
#' @param study_path Path to the study folder
#' @param operation Description of the operation being attempted
#' @return Logical indicating if the operation can proceed
#' @keywords internal
can_write_study <- function(study_path, operation = "write to study folder") {
  if (is_study_locked(study_path)) {
    warning(
      "Cannot ", operation, ": study folder is locked\n",
      "  Path: ", study_path, "\n",
      "  Use unlock_study() to remove the lock for this session.",
      call. = FALSE
    )
    return(FALSE)
  }
  TRUE
}

#' Package onLoad hook
#'
#' @description
#' Called when the package is loaded. Registers bundled and cached study
#' folders as locked (in memory) to prevent accidental data modification.
#' No files are written to disk.
#'
#' @param libname Library name
#' @param pkgname Package name
#' @keywords internal
.onLoad <- function(libname, pkgname) {
  pkg_path <- system.file(package = pkgname, lib.loc = libname)

  exampledata_path <- file.path(pkg_path, "exampledata")

  if (dir.exists(exampledata_path)) {
    study_folders <- list.dirs(
      exampledata_path,
      recursive = FALSE,
      full.names = TRUE
    )

    for (folder in study_folders) {
      lock_study(folder, reason = "Bundled data - protected from overwrites")
    }
  }

  # Also lock any previously downloaded (cached) studies

  cd <- tools::R_user_dir("clinTrialData", "cache")
  if (dir.exists(cd)) {
    cached_folders <- list.dirs(cd, recursive = FALSE, full.names = TRUE)
    for (folder in cached_folders) {
      lock_study(folder, reason = "Cached data - protected from overwrites")
    }
  }
}
