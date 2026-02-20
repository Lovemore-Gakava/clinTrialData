test_that("list_data_sources works", {
  sources <- list_data_sources()

  expect_s3_class(sources, "data.frame")
  expect_gt(nrow(sources), 0)
  expect_true("cdisc_pilot" %in% sources$source)
  expect_named(sources, c("source", "description", "domains", "format", "location"))
  expect_true(all(sources$location %in% c("bundled", "cached")))
})

test_that("list_data_sources reads description from metadata.json", {
  sources <- list_data_sources()
  pilot <- sources[sources$source == "cdisc_pilot", ]

  # Description should come from metadata.json, not a hardcoded switch
  expect_true(nchar(pilot$description) > 0)
  expect_false(identical(pilot$description, "cdisc_pilot"))  # not just the name
})

test_that("connect_clinical_data validates input", {
  skip_if_not_installed("connector")

  expect_error(
    connect_clinical_data("nonexistent_source"),
    "Unknown data source: 'nonexistent_source'"
  )
})

test_that("connect_clinical_data works with valid source", {
  skip_if_not_installed("connector")

  db <- connect_clinical_data("cdisc_pilot")

  expect_s3_class(db, "connectors")
  expect_true("adam" %in% names(db))
  expect_true("sdtm" %in% names(db))
})

test_that("connect_clinical_data uses default source", {
  skip_if_not_installed("connector")

  # Test default parameter (should be cdisc_pilot)
  db <- connect_clinical_data()

  expect_s3_class(db, "connectors")
  expect_true("adam" %in% names(db))
  expect_true("sdtm" %in% names(db))
})
