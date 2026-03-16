# Package-level environment for in-memory lock tracking.
# Populated at load time; no files are written to the installation directory.
.lock_env <- new.env(parent = emptyenv())
.lock_env$locked_paths <- character(0)

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
#' The lock is in-memory only: no file-system permissions are modified.
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

  invisible(TRUE)
}

#' Unlock a study folder
#'
#' @description
#' Removes the in-memory lock on a study path, allowing write operations
#' for the remainder of the current R session.
#'
#' @param study_path Path to the study folder
#' @return Logical indicating success, invisibly
#' @keywords internal
unlock_study <- function(study_path) {
  np <- normalizePath(study_path, mustWork = FALSE)
  .lock_env$locked_paths <- setdiff(.lock_env$locked_paths, np)
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
#' folders as locked (in memory only) to prevent accidental data modification.
#' No files are written to disk and no file-system permissions are changed.
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
