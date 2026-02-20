# Script to automatically discover and
# convert CDISC Pilot 01 XPT files to Parquet

library(arrow)
library(haven)
library(dplyr)
library(httr)
library(jsonlite)

# Source the lock functions
source("R/lock.R")

# Define paths
output_base <- "inst/exampledata/cdisc_pilot"

# Check if the output directory is locked
if (dir.exists(output_base) && is_study_locked(output_base)) {
  status <- get_lock_status(output_base)
  stop(
    "Cannot prepare CDISC Pilot data: study folder is locked\n",
    "  Path: ",
    output_base,
    "\n",
    "  Locked at: ",
    status$locked_at,
    "\n",
    "  Reason: ",
    status$reason,
    "\n",
    "  To unlock and regenerate data, run: unlock_study('",
    output_base,
    "')",
    call. = FALSE
  )
}

# CDISC Pilot data source base URL
base_path <- paste0(
  "master/updated-pilot-submission-package/900172/m5/datasets/",
  "cdiscpilot01"
)
repo_url <- "https://github.com/cdisc-org/sdtm-adam-pilot-project"

# Construct URLs for raw files and browsing
adam_url_base <- paste0(repo_url, "/raw/", base_path, "/analysis/adam/datasets")
sdtm_url_base <- paste0(repo_url, "/raw/", base_path, "/tabulations/sdtm")
adam_tree_url <- paste0(
  repo_url,
  "/tree/",
  base_path,
  "/analysis/adam/datasets"
)
sdtm_tree_url <- paste0(repo_url, "/tree/", base_path, "/tabulations/sdtm")

# Create temporary directory for downloads
temp_dir <- tempdir()

# Function to discover XPT files using GitHub API
discover_xpt_files <- function(repo_owner, repo_name, path) {
  # Construct GitHub API URL
  api_url <- paste0(
    "https://api.github.com/repos/",
    repo_owner,
    "/",
    repo_name,
    "/contents/",
    path
  )

  message("Discovering files at: ", api_url)

  tryCatch(
    {
      # Make API request with proper headers
      response <- httr::GET(
        api_url,
        httr::add_headers("User-Agent" = "R-clinTrialData")
      )

      if (httr::status_code(response) == 200) {
        content <- httr::content(response, "text", encoding = "UTF-8")
        files_data <- jsonlite::fromJSON(content, simplifyVector = TRUE)

        if (is.data.frame(files_data)) {
          # Filter for XPT files
          xpt_files <- files_data$name[
            grepl("\\.xpt$", files_data$name, ignore.case = TRUE)
          ]

          if (length(xpt_files) > 0) {
            message(
              "✓ Found ",
              length(xpt_files),
              " XPT files: ",
              paste(xpt_files, collapse = ", ")
            )
            return(xpt_files)
          } else {
            message("No XPT files found in directory")
            character(0)
          }
        } else {
          warning("Unexpected API response format")
          character(0)
        }
      } else {
        warning(
          "GitHub API request failed with status: ",
          httr::status_code(response)
        )
        character(0)
      }
    },
    error = function(e) {
      warning("Error accessing GitHub API: ", e$message)
      character(0)
    }
  )
}

# Function to download and convert XPT files to Parquet
download_and_convert_xpt <- function(url, filename, output_dir, domain) {
  tryCatch(
    {
      # Create output directory if it doesn't exist
      dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

      # Define file paths
      local_file <- file.path(temp_dir, filename)
      output_file <- file.path(
        output_dir,
        sub("\\.xpt$", ".parquet", filename, ignore.case = TRUE)
      )

      # Skip if file already exists
      if (file.exists(output_file)) {
        message("⏭ Skipping ", filename, " (already exists)")
        return(TRUE)
      }

      # Download XPT file
      message("⬇ Downloading ", filename, "...")
      utils::download.file(url, local_file, mode = "wb", quiet = TRUE)

      # Read XPT file
      message("📖 Reading ", filename, "...")
      data <- haven::read_xpt(local_file)

      # Write as Parquet
      message("💾 Converting to Parquet...")
      arrow::write_parquet(data, output_file)

      message(
        "✓ Converted ",
        basename(output_file),
        " (",
        nrow(data),
        " rows, ",
        ncol(data),
        " columns)"
      )

      # Clean up individual file
      unlink(local_file)

      TRUE
    },
    error = function(e) {
      warning("✗ Failed to process ", filename, ": ", e$message)
      FALSE
    }
  )
}

# Fallback lists in case scraping fails (based on actual repository contents)
adam_fallback <- c(
  "adsl.xpt",
  "adae.xpt",
  "adlbc.xpt",
  "advs.xpt",
  "adlbh.xpt",
  "adlbhy.xpt",
  "adqsadas.xpt",
  "adqscibc.xpt",
  "adqsnpix.xpt",
  "adtte.xpt"
)
sdtm_fallback <- c(
  "dm.xpt",
  "ae.xpt",
  "vs.xpt",
  "lb.xpt",
  "ex.xpt",
  "sv.xpt",
  "cm.xpt",
  "mh.xpt",
  "ds.xpt",
  "qs.xpt",
  "sc.xpt",
  "se.xpt",
  "suppae.xpt",
  "suppdm.xpt",
  "suppds.xpt",
  "supplb.xpt",
  "ta.xpt",
  "te.xpt",
  "ti.xpt",
  "ts.xpt",
  "tv.xpt",
  "relrec.xpt"
)

# Discover ADaM datasets using GitHub API
message("\n=== Discovering ADaM datasets ===\n")
adam_datasets <- discover_xpt_files(
  "cdisc-org",
  "sdtm-adam-pilot-project",
  paste0(
    "updated-pilot-submission-package/900172/m5/datasets/",
    "cdiscpilot01/analysis/adam/datasets"
  )
)

if (length(adam_datasets) == 0) {
  message("API discovery failed, using fallback list")
  adam_datasets <- adam_fallback
  message("ADaM datasets: ", paste(adam_datasets, collapse = ", "))
}

# Convert ADaM datasets
message("\n=== Converting ADaM datasets ===\n")
adam_success <- 0
for (dataset in adam_datasets) {
  if (
    download_and_convert_xpt(
      url = paste0(adam_url_base, "/", dataset),
      filename = dataset,
      output_dir = file.path(output_base, "adam"),
      domain = "adam"
    )
  ) {
    adam_success <- adam_success + 1
  }
}

# Discover SDTM datasets using GitHub API
message("\n=== Discovering SDTM datasets ===\n")
sdtm_datasets <- discover_xpt_files(
  "cdisc-org",
  "sdtm-adam-pilot-project",
  paste0(
    "updated-pilot-submission-package/900172/m5/datasets/",
    "cdiscpilot01/tabulations/sdtm"
  )
)

if (length(sdtm_datasets) == 0) {
  message("API discovery failed, using fallback list")
  sdtm_datasets <- sdtm_fallback
  message("SDTM datasets: ", paste(sdtm_datasets, collapse = ", "))
}

# Convert SDTM datasets
message("\n=== Converting SDTM datasets ===\n")
sdtm_success <- 0
for (dataset in sdtm_datasets) {
  if (
    download_and_convert_xpt(
      url = paste0(sdtm_url_base, "/", dataset),
      filename = dataset,
      output_dir = file.path(output_base, "sdtm"),
      domain = "sdtm"
    )
  ) {
    sdtm_success <- sdtm_success + 1
  }
}

# Combine adlbc, adlbh, adlbhy into adlb
message("\n=== Combining Laboratory Datasets ===\n")
tryCatch(
  {
    adam_dir <- file.path(output_base, "adam")
    adlbc_file <- file.path(adam_dir, "adlbc.parquet")
    adlbh_file <- file.path(adam_dir, "adlbh.parquet")
    adlbhy_file <- file.path(adam_dir, "adlbhy.parquet")
    adlb_file <- file.path(adam_dir, "adlb.parquet")

    # Check if all three source files exist
    if (file.exists(adlbc_file) && file.exists(adlbh_file) &&
          file.exists(adlbhy_file)) {
      message("📖 Reading adlbc, adlbh, and adlbhy...")

      # Read the three datasets
      adlbc <- arrow::read_parquet(adlbc_file)
      adlbh <- arrow::read_parquet(adlbh_file)
      adlbhy <- arrow::read_parquet(adlbhy_file)

      message(
        "  adlbc: ",
        nrow(adlbc),
        " rows, ",
        ncol(adlbc),
        " columns"
      )
      message(
        "  adlbh: ",
        nrow(adlbh),
        " rows, ",
        ncol(adlbh),
        " columns"
      )
      message(
        "  adlbhy: ",
        nrow(adlbhy),
        " rows, ",
        ncol(adlbhy),
        " columns"
      )

      # Combine datasets using bind_rows (handles different column sets)
      message("🔗 Combining datasets...")
      adlb <- dplyr::bind_rows(adlbc, adlbh, adlbhy)

      # Write combined dataset
      message("💾 Writing adlb.parquet...")
      arrow::write_parquet(adlb, adlb_file)

      message(
        "✓ Created adlb.parquet (",
        nrow(adlb),
        " rows, ",
        ncol(adlb),
        " columns)"
      )
    } else {
      message("⚠ Not all source files exist, skipping ADLB creation")
      if (!file.exists(adlbc_file)) message("  Missing: adlbc.parquet")
      if (!file.exists(adlbh_file)) message("  Missing: adlbh.parquet")
      if (!file.exists(adlbhy_file)) message("  Missing: adlbhy.parquet")
    }
  },
  error = function(e) {
    warning("✗ Failed to create ADLB: ", e$message)
  }
)

# Summary
message("\n=== Conversion Summary ===")
message(
  "ADaM datasets: ",
  adam_success,
  "/",
  length(adam_datasets),
  " converted successfully"
)
message(
  "SDTM datasets: ",
  sdtm_success,
  "/",
  length(sdtm_datasets),
  " converted successfully"
)
message(
  "Total: ",
  adam_success + sdtm_success,
  "/",
  length(adam_datasets) + length(sdtm_datasets),
  " datasets converted"
)

# List created files
message("\n=== Created Parquet files ===")
adam_files <- list.files(
  file.path(output_base, "adam"),
  pattern = "\\.parquet$",
  full.names = FALSE
)
sdtm_files <- list.files(
  file.path(output_base, "sdtm"),
  pattern = "\\.parquet$",
  full.names = FALSE
)

message("\nADaM (", length(adam_files), " files):")
for (f in adam_files) {
  message("  - ", f)
}

message("\nSDTM (", length(sdtm_files), " files):")
for (f in sdtm_files) {
  message("  - ", f)
}

# Clean up temp directory
unlink(temp_dir, recursive = TRUE)

message("\n✓ CDISC Pilot data preparation complete!")
