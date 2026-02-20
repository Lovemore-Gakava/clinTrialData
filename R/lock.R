#' Check if a study folder is locked
#'
#' @description
#' Checks if a lock file exists for a study folder, indicating that the folder
#' should not be overwritten (typically because the package has been installed).
#'
#' @param study_path Path to the study folder
#' @return Logical indicating if the folder is locked
#' @keywords internal
is_study_locked <- function(study_path) {
  lock_file <- file.path(study_path, ".lock")
  file.exists(lock_file)
}

#' Create a lock file for a study folder
#'
#' @description
#' Creates a lock file to prevent overwriting of a study folder.
#' This is typically called after package installation to protect
#' the installed data from being overwritten by data-raw scripts.
#'
#' @param study_path Path to the study folder
#' @param reason Optional reason for the lock (default: "Package installed")
#' @return Logical indicating success
#' @keywords internal
lock_study <- function(study_path, reason = "Package installed") {
  if (!dir.exists(study_path)) {
    warning("Study folder does not exist: ", study_path)
    return(FALSE)
  }

  lock_file <- file.path(study_path, ".lock")

  # Create lock file with metadata
  lock_data <- list(
    locked_at = Sys.time(),
    reason = reason,
    hostname = Sys.info()["nodename"],
    user = Sys.info()["user"],
    r_version = paste(R.version$major, R.version$minor, sep = ".")
  )

  tryCatch(
    {
      writeLines(
        c(
          paste("# Study folder lock file"),
          paste("# Created:", lock_data$locked_at),
          paste("# Reason:", lock_data$reason),
          paste("# Hostname:", lock_data$hostname),
          paste("# User:", lock_data$user),
          paste("# R version:", lock_data$r_version),
          "",
          "# This file prevents data-raw scripts from overwriting ",
          "# this study folder.",
          "# To unlock, delete this file."
        ),
        lock_file
      )
      message("Locked study folder: ", study_path)
      TRUE
    },
    error = function(e) {
      warning("Failed to create lock file: ", e$message)
      FALSE
    }
  )
}

#' Unlock a study folder
#'
#' @description
#' Removes the lock file from a study folder, allowing it to be overwritten.
#'
#' @param study_path Path to the study folder
#' @return Logical indicating success
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' # Unlock a study folder to allow regeneration
#' unlock_study("inst/exampledata/cdisc_pilot")
#' }
unlock_study <- function(study_path) {
  lock_file <- file.path(study_path, ".lock")

  if (!file.exists(lock_file)) {
    message("Study folder is not locked: ", study_path)
    return(TRUE)
  }

  tryCatch(
    {
      file.remove(lock_file)
      message("Unlocked study folder: ", study_path)
      TRUE
    },
    error = function(e) {
      warning("Failed to remove lock file: ", e$message)
      FALSE
    }
  )
}

#' Lock all study folders
#'
#' @description
#' Locks all study folders in the inst/exampledata directory.
#' This is typically called during package installation via .onLoad.
#'
#' @param base_path Base path to the exampledata directory
#' @param reason Optional reason for the lock
#' @return Invisible list of locked folders
#' @keywords internal
lock_all_studies <- function(
    base_path = "inst/exampledata",
    reason = "Package installed") {
  if (!dir.exists(base_path)) {
    warning("Base path does not exist: ", base_path)
    return(invisible(character(0)))
  }

  # Find all study folders (subdirectories of base_path)
  study_folders <- list.dirs(base_path, recursive = FALSE, full.names = TRUE)

  if (length(study_folders) == 0) {
    message("No study folders found in: ", base_path)
    return(invisible(character(0)))
  }

  locked_folders <- character(0)
  for (folder in study_folders) {
    if (lock_study(folder, reason)) {
      locked_folders <- c(locked_folders, folder)
    }
  }

  message("Locked ", length(locked_folders), " study folder(s)")
  invisible(locked_folders)
}

#' Get lock status for a study folder
#'
#' @description
#' Returns information about the lock status of a study folder.
#'
#' @param study_path Path to the study folder
#' @return List with lock information or NULL if not locked
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' # Check lock status
#' status <- get_lock_status("inst/exampledata/cdisc_pilot")
#' print(status)
#' }
get_lock_status <- function(study_path) {
  lock_file <- file.path(study_path, ".lock")

  if (!file.exists(lock_file)) {
    return(list(
      locked = FALSE,
      path = study_path
    ))
  }

  # Read lock file
  lock_content <- readLines(lock_file, warn = FALSE)

  # Parse metadata from comments
  locked_at <- sub(
    "^# Created: ",
    "",
    lock_content[grep("^# Created:", lock_content)]
  )
  reason <- sub(
    "^# Reason: ",
    "",
    lock_content[grep("^# Reason:", lock_content)]
  )

  list(
    locked = TRUE,
    path = study_path,
    locked_at = if (length(locked_at) > 0) locked_at else NA,
    reason = if (length(reason) > 0) reason else NA
  )
}

#' Check if study folder should be written
#'
#' @description
#' Helper function to check if a study folder can be safely written to.
#' Returns TRUE if the folder can be written, FALSE if it's locked.
#' Issues a warning if the folder is locked.
#'
#' @param study_path Path to the study folder
#' @param operation Description of the operation being attempted
#' @return Logical indicating if the operation can proceed
#' @keywords internal
can_write_study <- function(study_path, operation = "write to study folder") {
  if (is_study_locked(study_path)) {
    status <- get_lock_status(study_path)
    warning(
      "Cannot ",
      operation,
      ": study folder is locked\n",
      "  Path: ",
      study_path,
      "\n",
      "  Locked at: ",
      status$locked_at,
      "\n",
      "  Reason: ",
      status$reason,
      "\n",
      "  This folder is automatically protected from modifications.",
      call. = FALSE
    )
    return(FALSE)
  }
  TRUE
}

#' Package onLoad hook
#'
#' @description
#' Called when the package is loaded. Locks study folders if this is an
#' installed package (not in development mode). Also registers S3 methods
#' for connector integration.
#'
#' @param libname Library name
#' @param pkgname Package name
#' @keywords internal
.onLoad <- function(libname, pkgname) {
  # Get the package installation path
  pkg_path <- system.file(package = pkgname, lib.loc = libname)

  # Only lock if this is an installed package (not in development)
  # Development mode is indicated by the package being loaded from the
  # current directory
  is_dev_mode <- file.exists(file.path(pkg_path, "..", "..", "DESCRIPTION")) &&
    file.exists(file.path(pkg_path, "..", "..", "R"))

  if (!is_dev_mode) {
    exampledata_path <- file.path(pkg_path, "exampledata")

    if (dir.exists(exampledata_path)) {
      # Find all study folders
      study_folders <- list.dirs(
        exampledata_path,
        recursive = FALSE,
        full.names = TRUE
      )

      # Lock each study folder that isn't already locked
      for (folder in study_folders) {
        if (!is_study_locked(folder)) {
          lock_study(
            folder,
            reason = "Package installed - protecting data from overwrites"
          )
        }
      }
    }
  }
}
