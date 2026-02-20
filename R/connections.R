#' Generate Connector Configuration from Directory Structure
#'
#' @description
#' Scans a data source directory and generates a connector configuration list
#' dynamically based on the available parquet files.
#'
#' @param source_path Path to the data source directory
#' @return A list suitable for passing to connector::connect()
#' @keywords internal
generate_connector_config <- function(source_path) {
  if (!dir.exists(source_path)) {
    stop("Data source directory not found: ", source_path)
  }

  # Find all subdirectories (adam, sdtm, output, etc.)
  subdirs <- list.dirs(source_path, recursive = FALSE, full.names = FALSE)
  subdirs <- subdirs[subdirs != ""]

  # Generate datasources for each subdirectory that contains parquet files
  datasources <- list()
  for (subdir in subdirs) {
    subdir_path <- file.path(source_path, subdir)
    parquet_files <- list.files(
      subdir_path,
      pattern = "\\.parquet$",
      full.names = FALSE
    )

    if (length(parquet_files) > 0) {
      datasources[[length(datasources) + 1]] <- list(
        name = subdir,
        backend = list(
          type = "connector_fs",
          path = file.path("{metadata.root_path}", subdir)
        )
      )
    }
  }

  # Return connector configuration list matching YAML structure
  list(
    metadata = list(
      root_path = "."
    ),
    datasources = datasources
  )
}

#' Connect to Data Source
#'
#' @description
#' Generic function to connect to any data source by scanning its directory
#' structure and generating the connector configuration dynamically.
#' Wraps all filesystem connectors with lock protection.
#'
#' Resolution order:
#' 1. User cache (downloaded via [download_study()])
#' 2. Package-bundled data (`inst/exampledata/`)
#'
#' @param source_name Name of the data source (e.g., "cdisc_pilot")
#' @return A `connectors` object
#' @keywords internal
connect_to_source <- function(source_name) {
  # 1. Check user cache first (populated by download_study())
  cached_path <- file.path(cache_dir(), source_name)

  # 2. Fall back to package-bundled data
  bundled_path <- system.file("exampledata", source_name, package = "clinTrialData")

  root_path <- if (dir.exists(cached_path)) {
    cached_path
  } else if (!is.null(bundled_path) && bundled_path != "" && dir.exists(bundled_path)) {
    bundled_path
  } else {
    stop(
      "Data source '", source_name, "' not found.\n",
      "If this is a remote dataset, download it first with:\n",
      "  download_study(\"", source_name, "\")"
    )
  }

  # Generate configuration dynamically
  config <- generate_connector_config(root_path)

  # Create the connector object
  conn_obj <- connector::connect(config, list(root_path = root_path))

  # Wrap each ConnectorFS with our lock protection
  conn_obj <- wrap_connectors_with_locks(conn_obj, root_path)

  conn_obj
}

#' Wrap Connectors with Lock Protection
#'
#' @description
#' Recursively wraps all ConnectorFS objects with lock protection.
#'
#' @param obj A connectors object or connector object
#' @param study_path Path to the study folder
#' @return The wrapped object
#' @keywords internal
wrap_connectors_with_locks <- function(obj, study_path) {
  if (inherits(obj, "ConnectorFS")) {
    # Add the locked class
    class(obj) <- c("ConnectorLockedFS", class(obj))
    # Store the study path for lock checking
    attr(obj, "study_path") <- study_path
  } else if (is.list(obj)) {
    # Recursively process list elements
    for (i in seq_along(obj)) {
      obj[[i]] <- wrap_connectors_with_locks(obj[[i]], study_path)
    }
  }

  obj
}

#' List Available Clinical Data Sources
#'
#' @description
#' Returns information about all clinical datasets available locally --
#' both datasets bundled with the package and any datasets previously
#' downloaded via [download_study()]. The `location` column indicates
#' whether a dataset is `"bundled"` (shipped with the package) or
#' `"cached"` (downloaded to the user cache directory).
#'
#' To see datasets available for download from GitHub, use
#' [list_available_studies()].
#'
#' @return A data frame with columns:
#'   \describe{
#'     \item{source}{Dataset name (pass to [connect_clinical_data()])}
#'     \item{description}{Human-readable study description}
#'     \item{domains}{Comma-separated list of available data domains
#'       (e.g. `"adam, sdtm"`)}
#'     \item{format}{Storage format (`"parquet"`)}
#'     \item{location}{Either `"bundled"` or `"cached"`}
#'   }
#' @export
#'
#' @examples
#' list_data_sources()
list_data_sources <- function() {
  # Collect (path, location) pairs - cached takes priority over bundled
  search_roots <- list()

  cd <- cache_dir()
  if (dir.exists(cd)) {
    search_roots[["cached"]] <- cd
  }

  bundled_path <- system.file("exampledata", package = "clinTrialData")
  if (!is.null(bundled_path) && bundled_path != "" && dir.exists(bundled_path)) {
    search_roots[["bundled"]] <- bundled_path
  }

  if (length(search_roots) == 0) {
    return(.empty_sources_df())
  }

  # Enumerate sources from each root, avoiding duplicates (cache wins)
  seen <- character(0)
  sources_info <- list()

  for (location in names(search_roots)) {
    root <- search_roots[[location]]
    dirs <- list.dirs(root, recursive = FALSE, full.names = FALSE)
    dirs <- dirs[dirs != ""]

    for (source in dirs) {
      if (source %in% seen) next  # cache already registered this source

      source_path <- file.path(root, source)
      domain_dirs <- list.dirs(source_path, recursive = FALSE, full.names = FALSE)
      domain_dirs <- domain_dirs[domain_dirs != ""]

      valid_domains <- character(0)
      for (domain in domain_dirs) {
        parquet_files <- list.files(
          file.path(source_path, domain),
          pattern = "\\.parquet$"
        )
        if (length(parquet_files) > 0) {
          valid_domains <- c(valid_domains, domain)
        }
      }

      if (length(valid_domains) == 0) next  # skip dirs without parquet data

      # Read description from metadata.json if available, else use source name
      description <- source
      meta_path <- file.path(source_path, "metadata.json")
      if (file.exists(meta_path)) {
        meta <- tryCatch(
          jsonlite::fromJSON(meta_path, simplifyVector = FALSE),
          error = function(e) NULL
        )
        if (!is.null(meta$description)) {
          description <- meta$description
        }
      }

      sources_info[[length(sources_info) + 1]] <- list(
        source      = source,
        description = description,
        domains     = paste(valid_domains, collapse = ", "),
        format      = "parquet",
        location    = location
      )
      seen <- c(seen, source)
    }
  }

  if (length(sources_info) == 0) {
    return(.empty_sources_df())
  }

  do.call(rbind, lapply(sources_info, data.frame, stringsAsFactors = FALSE))
}

#' @keywords internal
.empty_sources_df <- function() {
  data.frame(
    source      = character(0),
    description = character(0),
    domains     = character(0),
    format      = character(0),
    location    = character(0),
    stringsAsFactors = FALSE
  )
}

#' Connect to Clinical Data by Source
#'
#' @description
#' Generic connection function that allows access to any data source
#' in the package. Data sources are automatically discovered by scanning
#' the package's example data directory structure.
#'
#' @param source Character string specifying the data source.
#'   Use `list_data_sources()` to see all available options.
#'
#' @return A `connectors` object
#' @export
#'
#' @examples
#' \donttest{
#' # Connect to CDISC Pilot data
#' db <- connect_clinical_data("cdisc_pilot")
#'
#' # List available datasets
#' db$adam$list_content_cnt()
#'
#' # Read a dataset
#' adsl <- db$adam$read_cnt("adsl")
#'
#' # List available sources
#' list_data_sources()
#' }
connect_clinical_data <- function(source = "cdisc_pilot") {
  available_sources <- list_data_sources()$source

  if (!source %in% available_sources) {
    stop(
      "Unknown data source: '",
      source,
      "'\n",
      "Available sources: ",
      paste(available_sources, collapse = ", "),
      "\nUse list_data_sources() to see all options."
    )
  }

  connect_to_source(source)
}
