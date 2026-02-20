library(haven)
library(dplyr)

# Load ADLBC to get exact structure and subject data
load("adlbc.rda")

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
  distinct(USUBJID, AVISITN, .keep_all = TRUE)

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

# Filter out records with missing AVISITN before merging
subject_visits <- subject_visits %>%
  filter(!is.na(AVISITN))

# Create ADLBURI by expanding subject_visits with uri_params
adlburi <- merge(subject_visits, uri_params, all = TRUE)

# Add additional required columns
adlburi <- adlburi %>%
  mutate(
    # Analysis values - simulate realistic urinalysis results
    AVAL = case_when(
      PARAMCD == "UPROTEIN" ~ sample(
        c(0, 1, 2, 3),
        nrow(.),
        replace = TRUE,
        prob = c(0.7, 0.2, 0.08, 0.02)
      ),
      PARAMCD == "UGLUC" ~ sample(
        c(0, 1, 2, 3),
        nrow(.),
        replace = TRUE,
        prob = c(0.85, 0.1, 0.03, 0.02)
      ),
      PARAMCD == "UKETONE" ~ sample(
        c(0, 1, 2),
        nrow(.),
        replace = TRUE,
        prob = c(0.9, 0.08, 0.02)
      ),
      PARAMCD == "UBIL" ~ sample(
        c(0, 1, 2),
        nrow(.),
        replace = TRUE,
        prob = c(0.95, 0.04, 0.01)
      ),
      PARAMCD == "USPECGR" ~ round(runif(nrow(.), 1.005, 1.030), 3),
      PARAMCD == "UPH" ~ round(runif(nrow(.), 4.5, 8.0), 1),
      PARAMCD == "ULEUK" ~ sample(
        c(0, 1, 2, 3),
        nrow(.),
        replace = TRUE,
        prob = c(0.8, 0.15, 0.04, 0.01)
      ),
      PARAMCD == "UNITRITE" ~ sample(
        c(0, 1),
        nrow(.),
        replace = TRUE,
        prob = c(0.92, 0.08)
      ),
      PARAMCD == "UBLOOD" ~ sample(
        c(0, 1, 2, 3),
        nrow(.),
        replace = TRUE,
        prob = c(0.75, 0.2, 0.04, 0.01)
      ),
      PARAMCD == "UCREAT24" ~ round(runif(nrow(.), 2.4, 14.2), 1),
      PARAMCD == "UOXAL24" ~ round(runif(nrow(.), 345.0, 1270.0), 1),
      PARAMCD == "UOXALBSA" ~ round(runif(nrow(.), 777.5, 1864.2), 1),
      PARAMCD == "UOXALBSAU18" ~ round(runif(nrow(.), 777.5, 1864.2), 1)
    ),

    # Baseline flag
    ABLFL = ifelse(!is.na(AVISITN) & AVISITN == 0, "Y", "")
  )

# Calculate BASE properly - get baseline value for each subject-parameter combination
baseline_values <- adlburi %>%
  filter(ABLFL == "Y") %>%
  select(USUBJID, PARAMCD, BASE = AVAL)

# Join baseline values back to all records
adlburi <- adlburi %>%
  left_join(baseline_values, by = c("USUBJID", "PARAMCD")) %>%
  mutate(
    # Change from baseline (only for post-baseline visits)
    CHG = ifelse(is.na(AVISITN) | AVISITN == 0, NA_real_, AVAL - BASE),

    # Percent change from baseline
    PCHG = ifelse(is.na(AVISITN) | AVISITN == 0 | is.na(BASE) | BASE == 0, NA_real_, (CHG / BASE) * 100),

    # Analysis flags - only set for records with valid AVISITN
    ANL01FL = ifelse(!is.na(AVISITN), "Y", ""),

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

  # Arrange by subject, visit, parameter
  arrange(USUBJID, AVISITN, PARAMCD)

# Add labels to match ADLBC structure
attr(adlburi$STUDYID, "label") <- "Study Identifier"
attr(adlburi$SUBJID, "label") <- "Subject Identifier for the Study"
attr(adlburi$USUBJID, "label") <- "Unique Subject Identifier"
attr(adlburi$PARAM, "label") <- "Parameter"
attr(adlburi$PARAMCD, "label") <- "Parameter Code"
attr(adlburi$PARAMN, "label") <- "Parameter (N)"
attr(adlburi$AVAL, "label") <- "Analysis Value"
attr(adlburi$AVALU, "label") <- "Analysis Value Unit"
attr(adlburi$BASE, "label") <- "Baseline Value"
attr(adlburi$CHG, "label") <- "Change from Baseline"
attr(adlburi$PCHG, "label") <- "Percent Change from Baseline"
attr(adlburi$AVISIT, "label") <- "Analysis Visit"
attr(adlburi$AVISITN, "label") <- "Analysis Visit (N)"

# Save the dataset
save(adlburi, file = "adlburi.rda")

cat("ADLBURI dataset created with", nrow(adlburi), "records\n")
cat(
  "Parameters included:",
  paste(sort(unique(adlburi$PARAMCD)), collapse = ", "),
  "\n"
)
cat("Subjects included:", length(unique(adlburi$USUBJID)), "\n")
cat(
  "Visits included:",
  paste(sort(unique(adlburi$AVISIT)), collapse = ", "),
  "\n"
)
