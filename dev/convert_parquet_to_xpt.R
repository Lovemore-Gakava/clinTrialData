library(arrow)
library(haven)

# Directory containing parquet files
parquet_dir <- "inst/exampledata/cdisc_pilot_extended/adam"

# Get all parquet files
parquet_files <- list.files(parquet_dir, pattern = "\\.parquet$", full.names = TRUE)

# Convert each parquet file to XPT
for (parquet_file in parquet_files) {
  # Create output XPT filename
  xpt_file <- sub("\\.parquet$", ".xpt", parquet_file)

  cat("Converting:", basename(parquet_file), "->", basename(xpt_file), "\n")

  # Read parquet file
  data <- read_parquet(parquet_file)

  # Write to XPT format
  write_xpt(data, xpt_file)

  cat("  Completed:", basename(xpt_file), "\n")
}

cat("\nConversion complete! Converted", length(parquet_files), "files.\n")
