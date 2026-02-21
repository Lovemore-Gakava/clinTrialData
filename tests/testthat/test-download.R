test_that("cache_dir returns a character string", {
  cd <- cache_dir()
  expect_type(cd, "character")
  expect_length(cd, 1)
})

test_that("download_study errors without piggyback", {
  # Simulate piggyback not installed by mocking requireNamespace
  mockery::stub(download_study, "requireNamespace", FALSE)
  expect_error(
    download_study("cdisc_pilot"),
    "piggyback"
  )
})

test_that("list_available_studies errors without piggyback", {
  mockery::stub(list_available_studies, "requireNamespace", FALSE)
  expect_error(
    list_available_studies(),
    "piggyback"
  )
})

test_that("download_study reports cached study without downloading", {
  # Create a fake cached study directory
  fake_cache <- file.path(tempdir(), "clinTrialData_test_cache")
  fake_study <- file.path(fake_cache, "fake_study")
  dir.create(fake_study, recursive = TRUE)
  on.exit(unlink(fake_cache, recursive = TRUE))

  # Stub cache_dir to point at our temp dir
  mockery::stub(download_study, "cache_dir", fake_cache)

  expect_message(
    download_study("fake_study"),
    "already cached"
  )
})
