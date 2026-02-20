# Create ADSL
adsl_big <- readRDS("inst/exampledata/cdisc/adam/adsl.rds")

adsl_big$TRT01AN <- c(
  "Xanomeline Low Dose" = 1,
  "Xanomeline High Dose" = 2,
  "Placebo" = 3
)[adsl_big$TRT01A]
wh <- which(colnames(adsl_big) == "TRT01A")
new_col_order <- c(
  colnames(adsl_big)[seq_len(wh)],
  "TRT01AN",
  setdiff(
    colnames(adsl_big)[setdiff(seq_len(ncol(adsl_big)), seq_len(wh))],
    "TRT01AN"
  )
)
adsl_big <- adsl_big[, new_col_order]

adsl_big$TRT01PN <- c(
  "Xanomeline Low Dose" = 1,
  "Xanomeline High Dose" = 2,
  "Placebo" = 3
)[adsl_big$TRT01P]
wh <- which(colnames(adsl_big) == "TRT01P")
new_col_order <- c(
  colnames(adsl_big)[seq_len(wh)],
  "TRT01PN",
  setdiff(
    colnames(adsl_big)[setdiff(seq_len(ncol(adsl_big)), seq_len(wh))],
    "TRT01PN"
  )
)
adsl_big <- adsl_big[, new_col_order]

adsl_big$TRTDURY <- adsl_big$TRTDURD / 365.25
wh <- which(colnames(adsl_big) == "TRTDURD")
new_col_order <- c(
  colnames(adsl_big)[seq_len(wh)],
  "TRTDURY",
  setdiff(
    colnames(adsl_big)[setdiff(seq_len(ncol(adsl_big)), seq_len(wh))],
    "TRTDURY"
  )
)
adsl_big <- adsl_big[, new_col_order]

adsl_big |>
  arrow::write_parquet("inst/exampledata/cdisc/ex_data/adam/adsl.parquet")

# Create ADLB

adlb_big <- readRDS("inst/exampledata/cdisc/adam/adlb.rds")

adlb_big$TRT01AN <- c(
  "Xanomeline Low Dose" = 1,
  "Xanomeline High Dose" = 2,
  "Placebo" = 3
)[adlb_big$TRT01A]
wh <- which(colnames(adlb_big) == "TRT01A")
new_col_order <- c(
  colnames(adlb_big)[seq_len(wh)],
  "TRT01AN",
  setdiff(
    colnames(adlb_big)[setdiff(seq_len(ncol(adlb_big)), seq_len(wh))],
    "TRT01AN"
  )
)
adlb_big <- adlb_big[, new_col_order]

adlb_big$TRT01PN <- c(
  "Xanomeline Low Dose" = 1,
  "Xanomeline High Dose" = 2,
  "Placebo" = 3
)[adlb_big$TRT01P]
wh <- which(colnames(adlb_big) == "TRT01P")
new_col_order <- c(
  colnames(adlb_big)[seq_len(wh)],
  "TRT01PN",
  setdiff(
    colnames(adlb_big)[setdiff(seq_len(ncol(adlb_big)), seq_len(wh))],
    "TRT01PN"
  )
)
adlb_big <- adlb_big[, new_col_order]

adlb_big |>
  arrow::write_parquet("inst/exampledata/cdisc/ex_data/adam/adlb.parquet")
