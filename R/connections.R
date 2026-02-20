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
#' @param source_name Name of the data source (e.g., "cdisc_pilot")
#' @return A `connectors` object
#' @keywords internal
connect_to_source <- function(source_name) {
  root_path <- system.file("exampledata", source_name, package = "ctdata")

  if (root_path == "" || !dir.exists(root_path)) {
    stop("Data source '", source_name, "' not found in package installation.")
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
#' Returns information about all clinical datasets available in the package.
#'
#' @return A data frame with columns: source, description, domains, format
#' @export
#'
#' @examples
#' list_data_sources()
list_data_sources <- function() {
  exampledata_path <- system.file("exampledata", package = "ctdata")

  if (exampledata_path == "" || !dir.exists(exampledata_path)) {
    return(data.frame(
      source = character(0),
      description = character(0),
      domains = character(0),
      format = character(0),
      stringsAsFactors = FALSE
    ))
  }

  # Find all subdirectories in exampledata
  source_dirs <- list.dirs(
    exampledata_path,
    recursive = FALSE,
    full.names = FALSE
  )
  source_dirs <- source_dirs[source_dirs != ""]

  if (length(source_dirs) == 0) {
    return(data.frame(
      source = character(0),
      description = character(0),
      domains = character(0),
      format = character(0),
      stringsAsFactors = FALSE
    ))
  }

  # Generate information for each source
  sources_info <- lapply(source_dirs, function(source) {
    source_path <- file.path(exampledata_path, source)

    # Find domain directories (subdirectories with parquet files)
    domain_dirs <- list.dirs(source_path, recursive = FALSE, full.names = FALSE)
    domain_dirs <- domain_dirs[domain_dirs != ""]

    # Filter to only domains that contain parquet files
    valid_domains <- character(0)
    for (domain in domain_dirs) {
      domain_path <- file.path(source_path, domain)
      parquet_files <- list.files(domain_path, pattern = "\\.parquet$")
      if (length(parquet_files) > 0) {
        valid_domains <- c(valid_domains, domain)
      }
    }

    # Create description based on source name
    description <- switch(source,
      "cdisc_pilot" = "CDISC Pilot 01 Study",
      paste(source)
    )

    list(
      source = source,
      description = description,
      domains = paste(valid_domains, collapse = ", "),
      format = "parquet"
    )
  })

  # Convert to data frame
  do.call(rbind, lapply(sources_info, data.frame, stringsAsFactors = FALSE))
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
#' \dontrun{
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
