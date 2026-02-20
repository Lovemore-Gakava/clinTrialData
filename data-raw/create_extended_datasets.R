# Script to create extended CDISC pilot datasets
# This script reads the original cdisc_pilot datasets and adds extra variables
# based on the transformation logic in dev/setup-data.R

library(arrow)
library(dplyr)

# Source the lock functions
source("R/lock.R")

# Create output directory structure
output_dir <- "inst/exampledata/cdisc_pilot_extended"

# Check if the output directory is locked
if (dir.exists(output_dir) && is_study_locked(output_dir)) {
  status <- get_lock_status(output_dir)
  stop(
    "Cannot create extended datasets: study folder is locked\n",
    "  Path: ",
    output_dir,
    "\n",
    "  Locked at: ",
    status$locked_at,
    "\n",
    "  Reason: ",
    status$reason,
    "\n",
    "  To unlock and regenerate data, run: unlock_study('",
    output_dir,
    "')",
    call. = FALSE
  )
}

dir.create(
  file.path(output_dir, "adam"),
  recursive = TRUE,
  showWarnings = FALSE
)
dir.create(
  file.path(output_dir, "sdtm"),
  recursive = TRUE,
  showWarnings = FALSE
)

# Process ADSL
message("Processing ADSL...")
adsl <- read_parquet("inst/exampledata/cdisc_pilot/adam/adsl.parquet")

# Add TRT01AN (treatment numeric code) only if it doesn't exist
if (!"TRT01AN" %in% colnames(adsl) && "TRT01A" %in% colnames(adsl)) {
  adsl$TRT01AN <- c(
    "Xanomeline Low Dose" = 1,
    "Xanomeline High Dose" = 2,
    "Placebo" = 3
  )[adsl$TRT01A]
  wh <- which(colnames(adsl) == "TRT01A")
  new_col_order <- c(
    colnames(adsl)[seq_len(wh)],
    "TRT01AN",
    setdiff(
      colnames(adsl)[setdiff(seq_len(ncol(adsl)), seq_len(wh))],
      "TRT01AN"
    )
  )
  adsl <- adsl[, new_col_order]
}

# Add TRT01PN (planned treatment numeric code) only if it doesn't exist
if (!"TRT01PN" %in% colnames(adsl) && "TRT01P" %in% colnames(adsl)) {
  adsl$TRT01PN <- c(
    "Xanomeline Low Dose" = 1,
    "Xanomeline High Dose" = 2,
    "Placebo" = 3
  )[adsl$TRT01P]
  wh <- which(colnames(adsl) == "TRT01P")
  new_col_order <- c(
    colnames(adsl)[seq_len(wh)],
    "TRT01PN",
    setdiff(
      colnames(adsl)[setdiff(seq_len(ncol(adsl)), seq_len(wh))],
      "TRT01PN"
    )
  )
  adsl <- adsl[, new_col_order]
}

# Add TRTDURY (treatment duration in years) only if it doesn't exist
if (!"TRTDURY" %in% colnames(adsl)) {
  if ("TRTDURD" %in% colnames(adsl)) {
    adsl$TRTDURY <- adsl$TRTDURD / 365.25
    attr(adsl$TRTDURY, "label") <- "Duration of Treatment (years)"
    wh <- which(colnames(adsl) == "TRTDURD")
    new_col_order <- c(
      colnames(adsl)[seq_len(wh)],
      "TRTDURY",
      setdiff(
        colnames(adsl)[setdiff(seq_len(ncol(adsl)), seq_len(wh))],
        "TRTDURY"
      )
    )
    adsl <- adsl[, new_col_order]
  } else if ("TRTDUR" %in% colnames(adsl)) {
    adsl$TRTDURY <- adsl$TRTDUR / 365.25
    attr(adsl$TRTDURY, "label") <- "Duration of Treatment (years)"
    wh <- which(colnames(adsl) == "TRTDUR")
    new_col_order <- c(
      colnames(adsl)[seq_len(wh)],
      "TRTDURY",
      setdiff(
        colnames(adsl)[setdiff(seq_len(ncol(adsl)), seq_len(wh))],
        "TRTDURY"
      )
    )
    adsl <- adsl[, new_col_order]
  }
}

write_parquet(adsl, file.path(output_dir, "adam/adsl.parquet"))
message("ADSL complete")

# Process ADLB (and similar datasets that have TRT01A and TRT01P)
adam_files <- c(
  "adlb.parquet",
  "adlbc.parquet",
  "adlbh.parquet",
  "adlbhy.parquet"
)

for (file in adam_files) {
  file_path <- file.path("inst/exampledata/cdisc_pilot/adam", file)
  if (file.exists(file_path)) {
    message(paste("Processing", file, "..."))
    data <- read_parquet(file_path)

    # Add TRT01AN only if it doesn't exist and TRT01A exists
    if (!"TRT01AN" %in% colnames(data) && "TRT01A" %in% colnames(data)) {
      data$TRT01AN <- c(
        "Xanomeline Low Dose" = 1,
        "Xanomeline High Dose" = 2,
        "Placebo" = 3
      )[data$TRT01A]
      wh <- which(colnames(data) == "TRT01A")
      new_col_order <- c(
        colnames(data)[seq_len(wh)],
        "TRT01AN",
        setdiff(
          colnames(data)[setdiff(seq_len(ncol(data)), seq_len(wh))],
          "TRT01AN"
        )
      )
      data <- data[, new_col_order]
    }

    # Add TRT01PN only if it doesn't exist and TRT01P exists
    if (!"TRT01PN" %in% colnames(data) && "TRT01P" %in% colnames(data)) {
      data$TRT01PN <- c(
        "Xanomeline Low Dose" = 1,
        "Xanomeline High Dose" = 2,
        "Placebo" = 3
      )[data$TRT01P]
      wh <- which(colnames(data) == "TRT01P")
      new_col_order <- c(
        colnames(data)[seq_len(wh)],
        "TRT01PN",
        setdiff(
          colnames(data)[setdiff(seq_len(ncol(data)), seq_len(wh))],
          "TRT01PN"
        )
      )
      data <- data[, new_col_order]
    }

    # Add TRTDURY (treatment duration in years) only if it doesn't exist
    if (!"TRTDURY" %in% colnames(data)) {
      if ("TRTDURD" %in% colnames(data)) {
        data$TRTDURY <- data$TRTDURD / 365.25
        attr(data$TRTDURY, "label") <- "Duration of Treatment (years)"
        wh <- which(colnames(data) == "TRTDURD")
        new_col_order <- c(
          colnames(data)[seq_len(wh)],
          "TRTDURY",
          setdiff(
            colnames(data)[setdiff(seq_len(ncol(data)), seq_len(wh))],
            "TRTDURY"
          )
        )
        data <- data[, new_col_order]
      } else if ("TRTDUR" %in% colnames(data)) {
        data$TRTDURY <- data$TRTDUR / 365.25
        attr(data$TRTDURY, "label") <- "Duration of Treatment (years)"
        wh <- which(colnames(data) == "TRTDUR")
        new_col_order <- c(
          colnames(data)[seq_len(wh)],
          "TRTDURY",
          setdiff(
            colnames(data)[setdiff(seq_len(ncol(data)), seq_len(wh))],
            "TRTDURY"
          )
        )
        data <- data[, new_col_order]
      }
    }

    write_parquet(data, file.path(output_dir, "adam", file))
    message(paste(file, "complete"))
  }
}

# Process other ADAM files (copy as-is or with minimal changes)
other_adam_files <- c(
  "adae.parquet",
  "adqsadas.parquet",
  "adqscibc.parquet",
  "adqsnpix.parquet",
  "adtte.parquet",
  "advs.parquet"
)

for (file in other_adam_files) {
  file_path <- file.path("inst/exampledata/cdisc_pilot/adam", file)
  if (file.exists(file_path)) {
    message(paste("Processing", file, "..."))
    data <- read_parquet(file_path)

    # Add TRT01AN only if it doesn't exist and TRT01A exists
    if (!"TRT01AN" %in% colnames(data) && "TRT01A" %in% colnames(data)) {
      data$TRT01AN <- c(
        "Xanomeline Low Dose" = 1,
        "Xanomeline High Dose" = 2,
        "Placebo" = 3
      )[data$TRT01A]
      wh <- which(colnames(data) == "TRT01A")
      new_col_order <- c(
        colnames(data)[seq_len(wh)],
        "TRT01AN",
        setdiff(
          colnames(data)[setdiff(seq_len(ncol(data)), seq_len(wh))],
          "TRT01AN"
        )
      )
      data <- data[, new_col_order]
    }

    # Add TRT01PN only if it doesn't exist and TRT01P exists
    if (!"TRT01PN" %in% colnames(data) && "TRT01P" %in% colnames(data)) {
      data$TRT01PN <- c(
        "Xanomeline Low Dose" = 1,
        "Xanomeline High Dose" = 2,
        "Placebo" = 3
      )[data$TRT01P]
      wh <- which(colnames(data) == "TRT01P")
      new_col_order <- c(
        colnames(data)[seq_len(wh)],
        "TRT01PN",
        setdiff(
          colnames(data)[setdiff(seq_len(ncol(data)), seq_len(wh))],
          "TRT01PN"
        )
      )
      data <- data[, new_col_order]
    }

    # Add TRTDURY (treatment duration in years) only if it doesn't exist
    if (!"TRTDURY" %in% colnames(data)) {
      if ("TRTDURD" %in% colnames(data)) {
        data$TRTDURY <- data$TRTDURD / 365.25
        attr(data$TRTDURY, "label") <- "Duration of Treatment (years)"
        wh <- which(colnames(data) == "TRTDURD")
        new_col_order <- c(
          colnames(data)[seq_len(wh)],
          "TRTDURY",
          setdiff(
            colnames(data)[setdiff(seq_len(ncol(data)), seq_len(wh))],
            "TRTDURY"
          )
        )
        data <- data[, new_col_order]
      } else if ("TRTDUR" %in% colnames(data)) {
        data$TRTDURY <- data$TRTDUR / 365.25
        attr(data$TRTDURY, "label") <- "Duration of Treatment (years)"
        wh <- which(colnames(data) == "TRTDUR")
        new_col_order <- c(
          colnames(data)[seq_len(wh)],
          "TRTDURY",
          setdiff(
            colnames(data)[setdiff(seq_len(ncol(data)), seq_len(wh))],
            "TRTDURY"
          )
        )
        data <- data[, new_col_order]
      }
    }

    write_parquet(data, file.path(output_dir, "adam", file))
    message(paste(file, "complete"))
  }
}

# Create ADLBURI (Urinalysis dataset) based on ADLBC structure
message("Creating ADLBURI...")
adlbc <- read_parquet(
  "inst/exampledata/cdisc_pilot_extended/adam/adlbc.parquet"
)

# Get unique subject-visit combinations from ADLBC
subject_visits <- adlbc %>%
  select(
    STUDYID,
    SUBJID,
    USUBJID,
    TRTP,
    TRTPN,
    TRTA,
    TRTAN,
    TRTSDT,
    TRTEDT,
    AGE,
    AGEGR1,
    AGEGR1N,
    RACE,
    RACEN,
    SEX,
    COMP24FL,
    DSRAEFL,
    SAFFL,
    AVISIT,
    AVISITN,
    ADY,
    ADT,
    VISIT,
    VISITNUM
  ) %>%
  distinct(USUBJID, AVISITN, .keep_all = TRUE) %>%
  # Filter out records with missing AVISITN to ensure data quality
  filter(!is.na(AVISITN))

# Define urinalysis parameters
uri_params <- data.frame(
  PARAMCD = c(
    "UPROTEIN",
    "UGLUC",
    "UKETONE",
    "UBIL",
    "USPECGR",
    "UPH",
    "ULEUK",
    "UNITRITE",
    "UBLOOD",
    "UCREAT24",
    "UOXAL24",
    "UOXALBSA",
    "UOXALBSAU18"
  ),
  PARAM = c(
    "Urine Protein",
    "Urine Glucose",
    "Urine Ketones",
    "Urine Bilirubin",
    "Urine Specific Gravity",
    "Urine pH",
    "Urine Leukocyte Esterase",
    "Urine Nitrites",
    "Urine Blood",
    "24Hr Urinary Creatinine",
    "24Hr Urinary Oxalate",
    "24Hr All BSA Adj Ur Oxalate",
    "24Hr(<18yr)BSA Adj Ur Oxalate"
  ),
  PARAMN = 1:13,
  stringsAsFactors = FALSE
)

# Create ADLBURI by expanding subject_visits with uri_params
adlburi <- merge(subject_visits, uri_params, all = TRUE)

# Set seed for reproducibility
set.seed(123)

# Add additional required columns
adlburi <- adlburi %>%
  mutate(
    # Analysis values - simulate realistic urinalysis results
    AVAL = case_when(
      PARAMCD == "UPROTEIN" ~ sample(
        c(0, 1, 2, 3),
        n(),
        replace = TRUE,
        prob = c(0.7, 0.2, 0.08, 0.02)
      ),
      PARAMCD == "UGLUC" ~ sample(
        c(0, 1, 2, 3),
        n(),
        replace = TRUE,
        prob = c(0.85, 0.1, 0.03, 0.02)
      ),
      PARAMCD == "UKETONE" ~ sample(
        c(0, 1, 2),
        n(),
        replace = TRUE,
        prob = c(0.9, 0.08, 0.02)
      ),
      PARAMCD == "UBIL" ~ sample(
        c(0, 1, 2),
        n(),
        replace = TRUE,
        prob = c(0.95, 0.04, 0.01)
      ),
      PARAMCD == "USPECGR" ~ round(runif(n(), 1.005, 1.030), 3),
      PARAMCD == "UPH" ~ round(runif(n(), 4.5, 8.0), 1),
      PARAMCD == "ULEUK" ~ sample(
        c(0, 1, 2, 3),
        n(),
        replace = TRUE,
        prob = c(0.8, 0.15, 0.04, 0.01)
      ),
      PARAMCD == "UNITRITE" ~ sample(
        c(0, 1),
        n(),
        replace = TRUE,
        prob = c(0.92, 0.08)
      ),
      PARAMCD == "UBLOOD" ~ sample(
        c(0, 1, 2, 3),
        n(),
        replace = TRUE,
        prob = c(0.75, 0.2, 0.04, 0.01)
      ),
      PARAMCD == "UCREAT24" ~ round(runif(n(), 2.4, 14.2), 1),
      PARAMCD == "UOXAL24" ~ round(runif(n(), 345.0, 1270.0), 1),
      PARAMCD == "UOXALBSA" ~ round(runif(n(), 777.5, 1864.2), 1),
      PARAMCD == "UOXALBSAU18" ~ round(runif(n(), 777.5, 1864.2), 1)
    ),

    # Baseline flag (only for records with valid AVISITN)
    ABLFL = ifelse(!is.na(AVISITN) & AVISITN == 0, "Y", ""),

    # Units
    AVALU = case_when(
      PARAMCD %in%
        c(
          "UPROTEIN",
          "UGLUC",
          "UKETONE",
          "UBIL",
          "ULEUK",
          "UNITRITE",
          "UBLOOD"
        ) ~ "SCALE",
      PARAMCD == "USPECGR" ~ "SPECIFIC GRAVITY",
      PARAMCD == "UPH" ~ "pH",
      PARAMCD == "UCREAT24" ~ "umol/24h",
      PARAMCD %in% c("UOXAL24", "UOXALBSA", "UOXALBSAU18") ~ "umol/24h"
    ),

    # Reference range indicators
    ANRLO = case_when(
      PARAMCD == "USPECGR" ~ 1.003,
      PARAMCD == "UPH" ~ 4.6,
      TRUE ~ NA_real_
    ),
    ANRHI = case_when(
      PARAMCD == "USPECGR" ~ 1.030,
      PARAMCD == "UPH" ~ 8.0,
      TRUE ~ NA_real_
    ),

    # Shift variables
    SHIFT1 = "",

    # Sequence number
    ASEQ = row_number()
  ) %>%
  # Calculate baseline values per subject-parameter combination
  group_by(USUBJID, PARAMCD) %>%
  mutate(
    BASE = AVAL[ABLFL == "Y"][1]
  ) %>%
  ungroup() %>%
  # Calculate change from baseline
  mutate(
    CHG = ifelse(is.na(AVISITN) | AVISITN == 0 | is.na(BASE), NA_real_, AVAL - BASE),
    PCHG = ifelse(
      is.na(AVISITN) | AVISITN == 0 | is.na(BASE) | BASE == 0,
      NA_real_,
      (CHG / BASE) * 100
    ),
    # Analysis flags - only set for records with valid AVISITN
    ANL01FL = ifelse(!is.na(AVISITN), "Y", "")
  ) %>%
  # Arrange by subject, visit, parameter
  arrange(USUBJID, AVISITN, PARAMCD)

write_parquet(adlburi, file.path(output_dir, "adam/adlburi.parquet"))
message(paste("ADLBURI created with", nrow(adlburi), "records"))

# Combine adlbc, adlbh, adlbhy, and adlburi into adlb
message("\n=== Combining Laboratory Datasets ===")
tryCatch(
  {
    adam_dir <- file.path(output_dir, "adam")
    adlbc_file <- file.path(adam_dir, "adlbc.parquet")
    adlbh_file <- file.path(adam_dir, "adlbh.parquet")
    adlbhy_file <- file.path(adam_dir, "adlbhy.parquet")
    adlburi_file <- file.path(adam_dir, "adlburi.parquet")
    adlb_file <- file.path(adam_dir, "adlb.parquet")

    # Check if all four source files exist
    all_exist <- file.exists(adlbc_file) && file.exists(adlbh_file) &&
      file.exists(adlbhy_file) && file.exists(adlburi_file)

    if (all_exist) {
      message("Reading adlbc, adlbh, adlbhy, and adlburi...")

      # Read the four datasets
      adlbc <- read_parquet(adlbc_file)
      adlbh <- read_parquet(adlbh_file)
      adlbhy <- read_parquet(adlbhy_file)
      adlburi <- read_parquet(adlburi_file)

      message(
        sprintf(
          "  adlbc: %d rows, %d columns",
          nrow(adlbc),
          ncol(adlbc)
        )
      )
      message(
        sprintf(
          "  adlbh: %d rows, %d columns",
          nrow(adlbh),
          ncol(adlbh)
        )
      )
      message(
        sprintf(
          "  adlbhy: %d rows, %d columns",
          nrow(adlbhy),
          ncol(adlbhy)
        )
      )
      message(
        sprintf(
          "  adlburi: %d rows, %d columns",
          nrow(adlburi),
          ncol(adlburi)
        )
      )

      # Combine datasets using bind_rows (handles different column sets)
      message("Combining datasets...")
      adlb <- bind_rows(adlbc, adlbh, adlbhy, adlburi)

      # Write combined dataset
      message("Writing adlb.parquet...")
      write_parquet(adlb, adlb_file)

      message(
        sprintf(
          "ADLB created with %d rows, %d columns",
          nrow(adlb),
          ncol(adlb)
        )
      )
    } else {
      message("Warning: Not all source files exist, skipping ADLB creation")
      if (!file.exists(adlbc_file)) message("  Missing: adlbc.parquet")
      if (!file.exists(adlbh_file)) message("  Missing: adlbh.parquet")
      if (!file.exists(adlbhy_file)) message("  Missing: adlbhy.parquet")
      if (!file.exists(adlburi_file)) message("  Missing: adlburi.parquet")
    }
  },
  error = function(e) {
    warning("Failed to create ADLB: ", e$message)
  }
)

# Copy SDTM files as-is (no transformations needed based on the example script)
message("\nCopying SDTM files...")
sdtm_files <- list.files(
  "inst/exampledata/cdisc_pilot/sdtm",
  pattern = "\\.parquet$",
  full.names = FALSE
)

for (file in sdtm_files) {
  data <- read_parquet(file.path("inst/exampledata/cdisc_pilot/sdtm", file))
  write_parquet(data, file.path(output_dir, "sdtm", file))
}

message("All datasets processed successfully!")
message(paste("Extended datasets created in:", output_dir))
