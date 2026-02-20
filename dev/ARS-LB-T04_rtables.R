# ============================================================================
# Program: ARS-LB-T04_rtables.R
# Purpose: Generate Table 14-3.04 - Summary of Observed and Change from
#          Baseline by Scheduled Visits - Urine Analysis Tests
# Package: rtables
#
# Status: PRODUCTION READY - Generates properly formatted RTF output suitable
#         for regulatory submissions
#
# Inputs:  - adsl.parquet (Safety population)
#          - adlburi.parquet (Urine analysis lab data)
# Outputs: - ARS-LB-T04_output.rtf (RTF format for submission)
#          - ARS-LB-T04_output.txt (ASCII format for review)
# ============================================================================

library(arrow)
library(dplyr)
library(tidyr)
library(rtables)
library(formatters)

# Read datasets
adsl <- read_parquet("inst/exampledata/cdisc_pilot_extended/adam/adsl.parquet")
adlburi <- read_parquet("inst/exampledata/cdisc_pilot_extended/adam/adlburi.parquet")

# Filter to safety population
adsl_safe <- adsl %>% filter(SAFFL == "Y")

# Merge datasets
data <- adlburi %>%
  filter(ANL01FL == "Y") %>%
  inner_join(adsl_safe %>% select(USUBJID, TRT01AN, TRT01A, SAFFL), by = "USUBJID")

# Create treatment variable as factor with proper ordering
data <- data %>%
  mutate(TRT = factor(TRT01A,
                      levels = c("Placebo", "Xanomeline Low Dose", "Xanomeline High Dose")))

# Get N for each treatment group
trt_n <- adsl_safe %>%
  group_by(TRT01A) %>%
  summarise(N = n(), .groups = "drop") %>%
  arrange(match(TRT01A, c("Placebo", "Xanomeline Low Dose", "Xanomeline High Dose")))

cat("\nTreatment Group Counts:\n")
print(trt_n)

# Analysis function for summary statistics
s_summary <- function(x) {
  # This function assumes we've already filtered out empty groups
  x_clean <- x[!is.na(x)]

  list(
    n = formatters::with_label(length(x_clean), "n"),
    mean_sd = formatters::with_label(
      sprintf("%.1f (%.2f)", mean(x_clean), sd(x_clean)),
      "Mean (SD)"
    ),
    median = formatters::with_label(
      sprintf("%.1f", median(x_clean)),
      "Median"
    ),
    min_max = formatters::with_label(
      sprintf("%.1f, %.1f", min(x_clean), max(x_clean)),
      "Min, Max"
    )
  )
}

# Function to create table for one parameter
create_param_table <- function(param_data, param_name) {

  cat("\nProcessing:", param_name, "\n")

  # Get unique visits in proper order
  visits <- param_data %>%
    filter(PARAM == param_name) %>%
    distinct(AVISIT, AVISITN) %>%
    arrange(AVISITN) %>%
    pull(AVISIT)

  # Filter to this parameter
  param_subset <- param_data %>%
    filter(PARAM == param_name) %>%
    mutate(AVISIT = factor(AVISIT, levels = visits))

  # Create basic table layout
  lyt <- basic_table(
    title = paste("Table 14-3.04"),
    subtitles = c(
      "Summary of Observed and Change from Baseline by Scheduled Visits - Urine Analysis Tests",
      paste("Parameter:", param_name),
      "Safety Population"
    ),
    main_footer = "Note: Baseline is defined as the last assessment that is non-missing prior to first dose of investigational product."
  ) %>%
    split_cols_by("TRT") %>%
    analyze(c("AVAL"), afun = function(x, .var, .spl_context) {
      s_summary(x)
    }, nested = FALSE)

  # Split by visit
  lyt <- lyt %>%
    split_rows_by("AVISIT", split_fun = drop_split_levels)

  # Build the table
  tbl <- build_table(lyt, param_subset)

  return(tbl)
}

# Create tables for each parameter separately
params <- unique(data$PARAM)

# Let's create a combined table with all parameters
# For rtables, we need to create a layout that nests parameters and visits

# Prepare data with visit type indicator
data_prepared <- data %>%
  mutate(
    # Create PARAM with units for display
    PARAM_DISPLAY = paste0(PARAM, " (", AVALU, ")"),
    visit_order = case_when(
      grepl("Baseline", AVISIT, ignore.case = TRUE) ~ AVISITN,
      TRUE ~ AVISITN
    ),
    is_baseline = grepl("Baseline", AVISIT, ignore.case = TRUE),
    visit_clean = trimws(AVISIT)
  )

# Check for visits with empty or problematic names
cat("\nChecking raw visit data...\n")
visit_check <- data_prepared %>%
  distinct(AVISIT, visit_clean, AVISITN, is_baseline) %>%
  arrange(AVISITN)
cat("Unique visits in data:\n")
print(visit_check)

# Add change from baseline rows
data_with_chg <- data_prepared %>%
  filter(!is_baseline) %>%
  mutate(
    stat_type = "Change from Baseline",
    visit_display = paste(visit_clean, "Change from Baseline"),
    value = CHG,
    visit_order = visit_order + 0.5
  ) %>%
  bind_rows(
    data_prepared %>%
      mutate(
        stat_type = "Observed",
        visit_display = visit_clean,
        value = AVAL
      )
  ) %>%
  arrange(PARAM_DISPLAY, visit_order, stat_type)

# Filter out visit_display combinations that have all NA values
# This prevents meaningless rows in the table
data_with_chg <- data_with_chg %>%
  group_by(PARAM_DISPLAY, visit_display, TRT) %>%
  filter(!all(is.na(value))) %>%
  ungroup()

# Check for and remove empty/whitespace-only visit names
cat("\nChecking for problematic visit_display values...\n")
problematic_visits <- data_with_chg %>%
  filter(is.na(visit_display) | trimws(visit_display) == "" | visit_display == ".") %>%
  distinct(AVISIT, visit_display, visit_clean)

if (nrow(problematic_visits) > 0) {
  cat("Found problematic visit names:\n")
  print(problematic_visits)

  # Remove rows with empty/whitespace visit names
  data_with_chg <- data_with_chg %>%
    filter(!is.na(visit_display) & trimws(visit_display) != "" & visit_display != ".")
}

# Get unique visit displays in order
visit_displays <- data_with_chg %>%
  distinct(PARAM_DISPLAY, visit_display, visit_order) %>%
  arrange(PARAM_DISPLAY, visit_order) %>%
  pull(visit_display) %>%
  unique()

cat("\nUnique visit_display values (in order):\n")
print(visit_displays)

data_with_chg <- data_with_chg %>%
  mutate(visit_display = factor(visit_display, levels = visit_displays))

# Create a vector of correct N values by treatment
# Order: Placebo, Xanomeline Low Dose, Xanomeline High Dose
col_counts_vec <- c(
  "Placebo" = trt_n$N[trt_n$TRT01A == "Placebo"],
  "Xanomeline Low Dose" = trt_n$N[trt_n$TRT01A == "Xanomeline Low Dose"],
  "Xanomeline High Dose" = trt_n$N[trt_n$TRT01A == "Xanomeline High Dose"]
)

cat("\nColumn counts (N):\n")
print(col_counts_vec)

# Create the main table layout
lyt <- basic_table(
  title = "Table 14-3.04",
  subtitles = c(
    "ARS-LB-T04: Summary of Observed and Change from Baseline by Scheduled Visits - Urine Analysis Tests",
    "Safety Population"
  ),
  main_footer = c(
    "Note: Baseline is defined as the last assessment that is non-missing prior to first dose of investigational product.",
    paste("Source: adsl, adlburi; Program: ARS-LB-T04_rtables.R; Run date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
  )
) %>%
  split_cols_by("TRT") %>%
  split_rows_by("PARAM_DISPLAY", split_fun = drop_split_levels, label_pos = "topleft", split_label = "Parameter (Units)\n  Visit") %>%
  split_rows_by("visit_display", split_fun = drop_split_levels) %>%
  analyze("value", afun = function(x, .var, .spl_context) {
    s_summary(x)
  }, show_labels = "hidden")

# Build table
cat("\n\nBuilding rtables table...\n")
result_table <- build_table(lyt, data_with_chg, col_counts = col_counts_vec)

# Print to console
cat("\n\nTable Preview:\n")
cat(toString(result_table, hsep = "-"))

# Export to ASCII text file
ascii_file <- "dev/ARS-LB-T04_output.txt"
export_as_txt(result_table, file = ascii_file, paginate = TRUE, lpp = 60)
cat("\n\nASCII output saved to:", ascii_file, "\n")

# Export to RTF with proper formatting
rtf_file <- "dev/ARS-LB-T04_output.rtf"
export_as_rtf(
  result_table,
  file = rtf_file,
  colwidths = NULL,  # Auto-calculate column widths
  font_size = 9,
  page_type = "letter",
  landscape = TRUE,
  margins = c(top = 0.5, bottom = 0.5, left = 0.75, right = 0.75)
)
cat("RTF output saved to:", rtf_file, "\n")

cat("\n\nTable generation complete!\n")
