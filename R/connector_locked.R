#' @importFrom connector write_cnt
#' @importFrom connector remove_cnt
NULL

#' Write Content with Lock Check
#'
#' @description
#' S3 method for write_cnt that checks if the study folder is locked
#' before allowing write operations.
#'
#' @param connector_object The ConnectorLockedFS object
#' @param x The data to write
#' @param name The file name
#' @param overwrite Whether to overwrite existing files
#' @param ... Additional arguments passed to the underlying connector
#' @return Invisible connector_object
#' @export
write_cnt.ConnectorLockedFS <- function(
    connector_object,
    x,
    name,
    overwrite = FALSE,
    ...) {
  # Get the study path where the lock file would be
  study_path <- attr(connector_object, "study_path")

  if (is.null(study_path)) {
    warning("No study_path attribute found on connector. Lock check skipped.")
  } else {
    # Check if the study folder is locked
    if (!can_write_study(study_path, operation = "write to study folder")) {
      stop(
        "Cannot write to locked study folder. ",
        "This folder is automatically protected.",
        call. = FALSE
      )
    }
  }

  # If not locked, proceed with the write using the parent method
  NextMethod("write_cnt")
}

#' Remove Content with Lock Check
#'
#' @description
#' S3 method for remove_cnt that checks if the study folder is locked
#' before allowing remove operations.
#'
#' @param connector_object The ConnectorLockedFS object
#' @param name The file name to remove
#' @param ... Additional arguments passed to the underlying connector
#' @return Invisible connector_object
#' @export
remove_cnt.ConnectorLockedFS <- function(connector_object, name, ...) {
  # Get the study path where the lock file would be
  study_path <- attr(connector_object, "study_path")

  if (is.null(study_path)) {
    warning("No study_path attribute found on connector. Lock check skipped.")
  } else {
    # Check if the study folder is locked
    if (!can_write_study(study_path, operation = "remove from study folder")) {
      stop(
        "Cannot remove from locked study folder. ",
        "This folder is automatically protected.",
        call. = FALSE
      )
    }
  }

  # If not locked, proceed with the removal using the parent method
  NextMethod("remove_cnt")
}
