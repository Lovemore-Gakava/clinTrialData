# Compare datasets between dev/ and inst/exampledata/cdisc_pilot_extended/
# This script helps verify data consistency and understand differences
# Uses arsenal package for detailed comparison reports

library(arrow)
library(arsenal)

# Compare ADAE
cat("=" , rep("=", 70), "\n", sep = "")
cat("ADAE Comparison\n")
cat("=" , rep("=", 70), "\n", sep = "")
dev_adae <- read_parquet("dev/adae.parquet")
ext_adae <- read_parquet("inst/exampledata/cdisc_pilot_extended/adam/adae.parquet")

cat("\nBasic Info:\n")
cat("  dev/: ", nrow(dev_adae), "rows,", ncol(dev_adae), "columns\n")
cat("  extended/: ", nrow(ext_adae), "rows,", ncol(ext_adae), "columns\n")

# Find common columns for comparison
common_cols_adae <- intersect(names(dev_adae), names(ext_adae))
cat("\nCommon columns:", length(common_cols_adae), "out of",
    length(union(names(dev_adae), names(ext_adae))), "total\n")
cat("  Only in dev/:", setdiff(names(dev_adae), names(ext_adae)), "\n")
cat("  Only in extended/:", setdiff(names(ext_adae), names(dev_adae)), "\n")

if (length(common_cols_adae) > 0) {
  cat("\nDetailed comparison using arsenal::comparedf():\n")
  comp_adae <- comparedf(
    dev_adae[, common_cols_adae],
    ext_adae[, common_cols_adae],
    by = intersect(c("USUBJID", "STUDYID"), common_cols_adae)
  )
  print(summary(comp_adae))
}

# Compare ADSL
cat("\n\n")
cat("=" , rep("=", 70), "\n", sep = "")
cat("ADSL Comparison\n")
cat("=" , rep("=", 70), "\n", sep = "")
dev_adsl <- read_parquet("dev/adsl.parquet")
ext_adsl <- read_parquet("inst/exampledata/cdisc_pilot_extended/adam/adsl.parquet")

cat("\nBasic Info:\n")
cat("  dev/: ", nrow(dev_adsl), "rows,", ncol(dev_adsl), "columns\n")
cat("  extended/: ", nrow(ext_adsl), "rows,", ncol(ext_adsl), "columns\n")

common_cols_adsl <- intersect(names(dev_adsl), names(ext_adsl))
cat("\nCommon columns:", length(common_cols_adsl), "out of",
    length(union(names(dev_adsl), names(ext_adsl))), "total\n")
cat("  Only in dev/:", setdiff(names(dev_adsl), names(ext_adsl)), "\n")
cat("  Only in extended/:", setdiff(names(ext_adsl), names(dev_adsl)), "\n")

if (length(common_cols_adsl) > 0) {
  cat("\nDetailed comparison using arsenal::comparedf():\n")
  comp_adsl <- comparedf(
    dev_adsl[, common_cols_adsl],
    ext_adsl[, common_cols_adsl],
    by = intersect(c("USUBJID", "STUDYID"), common_cols_adsl)
  )
  print(summary(comp_adsl))
}

# Compare ADLB vs ADLBC
cat("\n\n")
cat("=" , rep("=", 70), "\n", sep = "")
cat("ADLB vs ADLBC Comparison\n")
cat("=" , rep("=", 70), "\n", sep = "")
dev_adlb <- read_parquet("dev/adlb.parquet")
ext_adlbc <- read_parquet("inst/exampledata/cdisc_pilot_extended/adam/adlbc.parquet")

cat("\nBasic Info:\n")
cat("  dev/adlb: ", nrow(dev_adlb), "rows,", ncol(dev_adlb), "columns\n")
cat("  extended/adlbc: ", nrow(ext_adlbc), "rows,", ncol(ext_adlbc), "columns\n")
cat("  Note: These are different datasets (all lab vs Chemistry only)\n")

common_cols_adlb <- intersect(names(dev_adlb), names(ext_adlbc))
cat("\nCommon columns:", length(common_cols_adlb), "out of",
    length(union(names(dev_adlb), names(ext_adlbc))), "total\n")

# Summary
cat("\n\n")
cat("=" , rep("=", 70), "\n", sep = "")
cat("Summary\n")
cat("=" , rep("=", 70), "\n", sep = "")
cat("- dev/ contains older/test versions of datasets\n")
cat("- inst/exampledata/cdisc_pilot_extended/ contains complete datasets\n")
cat("- ADAE: dev version has fewer columns (11 vs 55)\n")
cat("- ADSL: different row counts and column counts\n")
cat("- ADLB vs ADLBC: fundamentally different datasets\n")
