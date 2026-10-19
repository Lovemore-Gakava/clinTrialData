# Script to create extended CDISC pilot datasets
# This script reads the original cdisc_pilot datasets and adds extra variables
# based on the transformation logic in dev/setup-data.R
#
# What the extended source adds on top of cdisc_pilot:
#   - TRT01AN / TRT01PN / TRTDURY numeric and derived variables
#   - ADSL: COUNTRY, RANDFL, TRTDURM, DTHCAUS, DTHCGR1, DCSREAS (issue #3)
#   - ADEXSUM exposure summary dataset (issue #3)
#   - AVISIT trimmed of leading blanks in all ADaM datasets (issue #3)
#   - ADLBURI urinalysis dataset -- SIMULATED values (set.seed(123)); it is
#     not part of the original CDISC pilot
#   - ADLB combining ADLBC, ADLBH, ADLBHY and ADLBURI
#
# Everything except ADLBURI is derived from data already in cdisc_pilot.

library(arrow)
library(dplyr)

# Source the lock functions
source("R/lock.R")

# Create output directory structure
source_dir <- "inst/exampledata/cdisc_pilot"
output_dir <- "inst/exampledata/cdisc_pilot_extended"

# Check if the output directory is locked
if (dir.exists(output_dir) && is_study_locked(output_dir)) {
  stop(
    "Cannot create extended datasets: study folder is locked\n",
    "  Path: ", output_dir, "\n",
    "  To unlock and regenerate data, run: unlock_study('", output_dir, "')",
    call. = FALSE
  )
}

# Remove stale artefacts from older builds (e.g. the file-based .lock from
# v0.1.0, which carried hostname/user details) so they are not re-zipped.
unlink(file.path(output_dir, ".lock"))

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

# Attach a variable label (read by arrow and haven on the way back in)
set_label <- function(x, label) {
  attr(x, "label") <- label
  x
}

# Trim leading/trailing blanks from AVISIT. The source XPT files pad AVISIT
# (e.g. "        Baseline"), which makes AVISIT == "Baseline" filters fail.
# See issue #3.
trim_avisit <- function(data) {
  if ("AVISIT" %in% names(data) && is.character(data$AVISIT)) {
    lbl <- attr(data$AVISIT, "label")
    data$AVISIT <- trimws(data$AVISIT)
    attr(data$AVISIT, "label") <- lbl
  }
  data
}

# Move `cols` to sit immediately after `anchor` (if both exist)
place_after <- function(data, cols, anchor) {
  cols <- intersect(cols, names(data))
  if (length(cols) == 0 || !anchor %in% names(data)) return(data)
  dplyr::relocate(data, dplyr::all_of(cols), .after = dplyr::all_of(anchor))
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

# -----------------------------------------------------------------------------
# ADSL additions for ARS-driven ARD generation (issue #3, requested by siera)
# Every variable is derived from data already in cdisc_pilot -- nothing is
# simulated.
# -----------------------------------------------------------------------------
message("Adding issue #3 ADSL variables...")

dm    <- read_parquet(file.path(source_dir, "sdtm/dm.parquet"))
ds    <- read_parquet(file.path(source_dir, "sdtm/ds.parquet"))
adae0 <- read_parquet(file.path(source_dir, "adam/adae.parquet"))

# COUNTRY: carried over from DM (ADaMIG standard ADSL variable)
adsl <- adsl %>%
  select(-any_of("COUNTRY")) %>%
  left_join(select(dm, USUBJID, COUNTRY), by = "USUBJID") %>%
  mutate(COUNTRY = set_label(COUNTRY, "Country"))

# RANDFL: every ADSL subject in the pilot was randomized (screen failures are
# in DM only), so RANDFL = "Y" for all ADSL records
adsl$RANDFL <- set_label(rep("Y", nrow(adsl)), "Randomized Population Flag")

# TRTDURM: treatment duration in months, as admiral::derive_vars_duration(
# out_unit = "months") -- days / (365.25 / 12)
adsl$TRTDURM <- set_label(
  as.numeric(adsl$TRTDUR) / 30.4375,
  "Duration of Treatment (months)"
)

# DTHCAUS / DTHCGR1: cause of death and treatment-emergent grouping.
# Primary source is the fatal AE (AESDTH == "Y", earliest if several); the
# fallback is DS.DSTERM for the death disposition record. Mirrors the
# admiral ADSL template (derive_vars_extreme_event()).
fatal_ae <- adae0 %>%
  filter(AESDTH == "Y") %>%
  arrange(USUBJID, ASTDT, AESEQ) %>%
  group_by(USUBJID) %>%
  slice(1) %>%
  ungroup() %>%
  transmute(USUBJID, AE_CAUSE = AEDECOD, AE_TRTEMFL = TRTEMFL)

ds_death <- ds %>%
  filter(toupper(DSDECOD) == "DEATH") %>%
  arrange(USUBJID, DSSTDTC) %>%
  group_by(USUBJID) %>%
  slice(1) %>%
  ungroup() %>%
  transmute(USUBJID, DS_CAUSE = DSTERM)

dm_death <- dm %>%
  filter(DTHFL == "Y") %>%
  transmute(USUBJID, DTHDT_ = as.Date(substr(DTHDTC, 1, 10)))

adsl <- adsl %>%
  left_join(fatal_ae, by = "USUBJID") %>%
  left_join(ds_death, by = "USUBJID") %>%
  left_join(dm_death, by = "USUBJID") %>%
  mutate(
    DTHCAUS = case_when(
      DTHFL != "Y"      ~ "",
      !is.na(AE_CAUSE)  ~ AE_CAUSE,
      !is.na(DS_CAUSE)  ~ DS_CAUSE,
      TRUE              ~ ""
    ),
    DTHCGR1 = case_when(
      DTHFL != "Y" ~ "",
      AE_TRTEMFL %in% "Y" ~ "Treatment-emergent",
      !is.na(DTHDT_) & !is.na(TRTEDT) & DTHDT_ <= TRTEDT + 30 ~
        "Treatment-emergent",
      TRUE ~ "Not treatment-emergent"
    ),
    DTHCAUS = set_label(DTHCAUS, "Cause of Death"),
    DTHCGR1 = set_label(DTHCGR1, "Cause of Death Group 1")
  ) %>%
  select(-AE_CAUSE, -AE_TRTEMFL, -DS_CAUSE, -DTHDT_)

# DCSREAS: ADaMIG name for the reason for discontinuation from study.
# Blank for completers; otherwise the existing DCREASCD value.
adsl$DCSREAS <- set_label(
  ifelse(toupper(adsl$DCDECOD) == "COMPLETED" | is.na(adsl$DCREASCD),
         "", adsl$DCREASCD),
  "Reason for Discontinuation from Study"
)

# Column placement close to related variables
adsl <- adsl %>%
  place_after("COUNTRY", "SITEGR1") %>%
  place_after("RANDFL", "SAFFL") %>%
  place_after("TRTDURM", "TRTDURY") %>%
  place_after(c("DTHCAUS", "DTHCGR1"), "DTHFL") %>%
  place_after("DCSREAS", "DCREASCD")

stopifnot(
  nrow(adsl) == length(unique(adsl$USUBJID)),
  sum(adsl$DTHFL == "Y") == sum(adsl$DTHCAUS != "")
)

write_parquet(adsl, file.path(output_dir, "adam/adsl.parquet"))
message("ADSL complete")

# -----------------------------------------------------------------------------
# ADEXSUM: exposure summary, one record per subject per parameter (issue #3)
#
# Duration and cumulative dose are taken from ADSL so ADEXSUM always agrees
# with ADSL.TRTDUR / ADSL.CUMDOSE (6 subjects have a missing EXENDTC, which
# ADSL already resolves via TRTEDT). Number of administrations counts dosing
# days from EX (the patch is applied once daily), with a missing EXENDTC
# imputed as ADSL.TRTEDT.
# -----------------------------------------------------------------------------
message("Creating ADEXSUM...")

ex <- read_parquet(file.path(source_dir, "sdtm/ex.parquet"))

nadmin <- ex %>%
  left_join(select(adsl, USUBJID, TRTEDT), by = "USUBJID") %>%
  mutate(
    EXSTDT = as.Date(substr(EXSTDTC, 1, 10)),
    EXENDT = as.Date(ifelse(
      is.na(EXENDTC) | EXENDTC == "",
      as.character(TRTEDT),
      substr(EXENDTC, 1, 10)
    )),
    NDAYS = as.numeric(EXENDT - EXSTDT) + 1
  ) %>%
  group_by(USUBJID) %>%
  summarise(NADMIN = sum(NDAYS, na.rm = TRUE), .groups = "drop")

exsum_base <- adsl %>%
  filter(SAFFL == "Y") %>%
  select(STUDYID, USUBJID, SUBJID, SITEID, TRT01A, TRT01AN, SAFFL,
         TRTSDT, TRTEDT, TRTDUR, CUMDOSE) %>%
  left_join(nadmin, by = "USUBJID")

params <- data.frame(
  PARAMN  = 1:4,
  PARAMCD = c("TRTDUR", "NADMIN", "PTIME", "CUMDOSE"),
  PARAM   = c(
    "Duration on Therapy (days)",
    "Number of Administrations",
    "Person Time (years)",
    "Cumulative Dose (mg)"
  ),
  AVALU   = c("DAYS", "ADMINISTRATIONS", "YEARS", "mg"),
  stringsAsFactors = FALSE
)

adexsum <- merge(exsum_base, params, all = TRUE) %>%
  mutate(
    AVAL = case_when(
      PARAMCD == "TRTDUR"  ~ as.numeric(TRTDUR),
      PARAMCD == "NADMIN"  ~ as.numeric(NADMIN),
      PARAMCD == "PTIME"   ~ as.numeric(TRTDUR) / 365.25,
      PARAMCD == "CUMDOSE" ~ as.numeric(CUMDOSE)
    ),
    AVALCAT1 = case_when(
      PARAMCD != "TRTDUR" | is.na(AVAL) ~ "",
      AVAL / 30.4375 < 6                ~ "< 6 months",
      TRUE                              ~ ">= 6 months"
    ),
    AEXTRT = TRT01A,
    TRTA   = TRT01A,
    TRTAN  = TRT01AN
  ) %>%
  arrange(USUBJID, PARAMN) %>%
  transmute(
    STUDYID  = set_label(STUDYID,  "Study Identifier"),
    USUBJID  = set_label(USUBJID,  "Unique Subject Identifier"),
    SUBJID   = set_label(SUBJID,   "Subject Identifier for the Study"),
    SITEID   = set_label(SITEID,   "Study Site Identifier"),
    TRT01A   = set_label(TRT01A,   "Actual Treatment for Period 01"),
    TRT01AN  = set_label(TRT01AN,  "Actual Treatment for Period 01 (N)"),
    TRTA     = set_label(TRTA,     "Actual Treatment"),
    TRTAN    = set_label(TRTAN,    "Actual Treatment (N)"),
    AEXTRT   = set_label(AEXTRT,   "Actual Treatment Received"),
    SAFFL    = set_label(SAFFL,    "Safety Population Flag"),
    TRTSDT   = set_label(TRTSDT,   "Date of First Exposure to Treatment"),
    TRTEDT   = set_label(TRTEDT,   "Date of Last Exposure to Treatment"),
    PARAMCD  = set_label(PARAMCD,  "Parameter Code"),
    PARAM    = set_label(PARAM,    "Parameter"),
    PARAMN   = set_label(PARAMN,   "Parameter (N)"),
    AVAL     = set_label(AVAL,     "Analysis Value"),
    AVALU    = set_label(AVALU,    "Analysis Value Unit"),
    AVALCAT1 = set_label(AVALCAT1, "Analysis Value Category 1")
  )

stopifnot(
  nrow(adexsum) == 4 * sum(adsl$SAFFL == "Y"),
  !anyNA(adexsum$AVAL)
)

write_parquet(adexsum, file.path(output_dir, "adam/adexsum.parquet"))
message("ADEXSUM created with ", nrow(adexsum), " records")

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

    data <- trim_avisit(data)
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

    data <- trim_avisit(data)
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
