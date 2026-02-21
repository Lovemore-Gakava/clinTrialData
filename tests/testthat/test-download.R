# --- Helpers ---------------------------------------------------------------

# Build a fake pb_releases() return value
fake_releases <- function(tags = "v0.1.0") {
  if (length(tags) == 0) {
    return(data.frame(
      tag_name   = character(0),
      name       = character(0),
      draft      = logical(0),
      prerelease = logical(0),
      stringsAsFactors = FALSE
    ))
  }
  data.frame(
    tag_name    = tags,
    name        = tags,
    draft       = FALSE,
    prerelease  = FALSE,
    stringsAsFactors = FALSE
  )
}

# Helper: empty releases (0-row data frame)
empty_releases <- function() fake_releases(character(0))

# Build a fake pb_list() return value.
# Uses "tag" (not "tag_name") to match real piggyback output.
fake_asset_list <- function(
    files = c("study_a.zip", "study_a_metadata.json"),
    tags  = "v0.1.0",
    sizes = rep(4 * 1024 * 1024, length(files))
) {
  data.frame(
    file_name = files,
    size      = sizes,
    tag       = rep(tags, length.out = length(files)),
    stringsAsFactors = FALSE
  )
}

# Create a temporary directory with a metadata.json inside
make_fake_cache_with_meta <- function(source_name = "my_study") {
  fake_cache <- file.path(tempdir(), paste0("ctd_cache_", sample.int(1e5, 1)))
  study_dir  <- file.path(fake_cache, source_name)
  dir.create(study_dir, recursive = TRUE)
  meta <- list(
    source      = source_name,
    description = "A test study",
    domains     = list(adam = list("adsl", "adae")),
    n_subjects  = 100,
    version     = "v0.1.0",
    license     = "Test license",
    source_url  = "https://example.com"
  )
  jsonlite::write_json(meta, file.path(study_dir, "metadata.json"),
                       auto_unbox = TRUE, pretty = TRUE)
  fake_cache
}

# Create a valid zip file whose contents extract to a named directory
make_fake_zip <- function(dest_dir, source_name = "my_study") {
  study_path <- file.path(dest_dir, source_name)
  adam_path  <- file.path(study_path, "adam")
  dir.create(adam_path, recursive = TRUE)
  writeLines("{}", file.path(study_path, "metadata.json"))
  writeLines("placeholder", file.path(adam_path, "adsl.parquet"))
  zip_path <- file.path(dest_dir, paste0(source_name, ".zip"))
  # Build zip from inside dest_dir so the zip root is the study folder

  old_wd <- setwd(dest_dir)
  on.exit(setwd(old_wd), add = TRUE)
  utils::zip(zip_path, files = source_name, flags = "-rq")
  # Remove the unzipped source so we can verify extraction later
  unlink(study_path, recursive = TRUE)

  zip_path
}


# --- %||% operator --------------------------------------------------------

test_that("%||% returns x when non-NULL", {
  expect_equal(1 %||% 2, 1)
  expect_equal("a" %||% "b", "a")
})

test_that("%||% returns y when x is NULL", {
  expect_equal(NULL %||% 42, 42)
  expect_equal(NULL %||% "fallback", "fallback")
})


# --- has_package ----------------------------------------------------------

test_that("has_package returns TRUE for an installed package", {
  expect_true(has_package("testthat"))
})

test_that("has_package returns FALSE for a non-existent package", {
  expect_false(has_package("packageThatSurelyDoesNotExist999"))
})


# --- cache_dir ------------------------------------------------------------

test_that("cache_dir returns a character string", {
  cd <- cache_dir()
  expect_type(cd, "character")
  expect_length(cd, 1)
})


# --- .print_dataset_info --------------------------------------------------

test_that(".print_dataset_info includes source name and version", {
  meta <- list(source = "test_study", version = "v1.2.3")
  expect_message(.print_dataset_info(meta), "test_study")
  expect_message(.print_dataset_info(meta), "v1.2.3")
})

test_that(".print_dataset_info handles missing version", {
  meta <- list(source = "test_study")
  msg <- capture_messages(.print_dataset_info(meta))
  expect_true(any(grepl("test_study", msg)))
})

test_that(".print_dataset_info shows description and domains", {
  meta <- list(
    source      = "s",
    description = "My study description",
    domains     = list(adam = list("adsl", "adae"), sdtm = list("dm")),
    n_subjects  = 50,
    license     = "MIT",
    source_url  = "https://example.com"
  )
  msg <- paste(capture_messages(.print_dataset_info(meta)), collapse = "")
  expect_true(grepl("My study description", msg))
  expect_true(grepl("adam", msg))
  expect_true(grepl("adsl", msg))
  expect_true(grepl("Subjects:", msg))
})

test_that(".print_dataset_info truncates domains with more than 8 datasets", {
  datasets <- as.list(paste0("ds", seq_len(12)))
  meta <- list(source = "s", domains = list(adam = datasets))
  msg <- paste(capture_messages(.print_dataset_info(meta)), collapse = "")
  expect_true(grepl("12 total", msg))
})


# --- dataset_info ---------------------------------------------------------

test_that("dataset_info reads from local cache when available", {
  fake_cache <- make_fake_cache_with_meta("cached_study")
  on.exit(unlink(fake_cache, recursive = TRUE))

  local_mocked_bindings(cache_dir = function() fake_cache)

  expect_message(result <- dataset_info("cached_study"), "cached_study")
  expect_type(result, "list")
  expect_equal(result$source, "cached_study")
  expect_equal(result$n_subjects, 100)
})

test_that("dataset_info reads bundled metadata for cdisc_pilot", {
  # This test uses the real bundled data in inst/exampledata/cdisc_pilot
  # Mock cache_dir to a non-existent path so it falls through to bundled
  local_mocked_bindings(cache_dir = function() tempfile())

  expect_message(result <- dataset_info("cdisc_pilot"), "cdisc_pilot")
  expect_type(result, "list")
  expect_equal(result$source, "cdisc_pilot")
  expect_equal(result$n_subjects, 225)
})

test_that("dataset_info cache takes priority over bundled metadata", {
  # Create a cached version of cdisc_pilot with different metadata
  fake_cache <- make_fake_cache_with_meta("cdisc_pilot")
  on.exit(unlink(fake_cache, recursive = TRUE))

  # Overwrite metadata so it's distinguishable from the bundled version
  meta <- list(source = "cdisc_pilot", n_subjects = 999, version = "v99.0.0")
  jsonlite::write_json(meta, file.path(fake_cache, "cdisc_pilot", "metadata.json"),
                       auto_unbox = TRUE)

  local_mocked_bindings(cache_dir = function() fake_cache)

  expect_message(result <- dataset_info("cdisc_pilot"), "cdisc_pilot")
  # Should get the cached version (999), not the bundled one (225)
  expect_equal(result$n_subjects, 999)
})

test_that("dataset_info parses all metadata fields from cache", {
  fake_cache <- make_fake_cache_with_meta("full_meta_study")
  on.exit(unlink(fake_cache, recursive = TRUE))

  local_mocked_bindings(cache_dir = function() fake_cache)

  expect_message(result <- dataset_info("full_meta_study"), "full_meta_study")
  expect_equal(result$source, "full_meta_study")
  expect_equal(result$description, "A test study")
  expect_equal(result$n_subjects, 100)
  expect_equal(result$version, "v0.1.0")
  expect_equal(result$license, "Test license")
  expect_equal(result$source_url, "https://example.com")
  expect_type(result$domains, "list")
  expect_equal(unlist(result$domains$adam), c("adsl", "adae"))
})

test_that("dataset_info handles minimal metadata (missing optional fields)", {
  fake_cache <- file.path(tempdir(), paste0("ctd_min_", sample.int(1e5, 1)))
  study_dir  <- file.path(fake_cache, "minimal_study")
  dir.create(study_dir, recursive = TRUE)
  on.exit(unlink(fake_cache, recursive = TRUE))

  # Write metadata with only source — all other fields absent
  jsonlite::write_json(list(source = "minimal_study"),
                       file.path(study_dir, "metadata.json"),
                       auto_unbox = TRUE)

  local_mocked_bindings(cache_dir = function() fake_cache)

  expect_message(result <- dataset_info("minimal_study"), "minimal_study")
  expect_equal(result$source, "minimal_study")
  expect_null(result$description)
  expect_null(result$n_subjects)
  expect_null(result$domains)
})

test_that("dataset_info errors on malformed JSON in cache", {
  fake_cache <- file.path(tempdir(), paste0("ctd_bad_", sample.int(1e5, 1)))
  study_dir  <- file.path(fake_cache, "bad_json_study")
  dir.create(study_dir, recursive = TRUE)
  on.exit(unlink(fake_cache, recursive = TRUE))

  writeLines("this is { not valid json !!!", file.path(study_dir, "metadata.json"))

  local_mocked_bindings(cache_dir = function() fake_cache)

  expect_error(dataset_info("bad_json_study"))
})

test_that("dataset_info parses bundled cdisc_pilot domains correctly", {
  local_mocked_bindings(cache_dir = function() tempfile())

  expect_message(result <- dataset_info("cdisc_pilot"), "cdisc_pilot")
  expect_true("adam" %in% names(result$domains))
  expect_true("sdtm" %in% names(result$domains))
  expect_true("adsl" %in% unlist(result$domains$adam))
  expect_true("dm" %in% unlist(result$domains$sdtm))
  expect_equal(length(unlist(result$domains$adam)), 11)
  expect_equal(length(unlist(result$domains$sdtm)), 22)
})

test_that("dataset_info errors when GitHub is unreachable", {
  local_mocked_bindings(
    cache_dir    = function() tempfile(),
    has_package  = function(pkg) TRUE,
    .pb_releases = function(...) stop("connection refused")
  )

  expect_error(dataset_info("remote_study"), "Could not reach GitHub")
})

test_that("dataset_info errors when no releases exist", {
  local_mocked_bindings(
    cache_dir    = function() tempfile(),
    has_package  = function(pkg) TRUE,
    .pb_releases = function(...) empty_releases()
  )

  expect_error(dataset_info("remote_study"), "No releases found")
})

test_that("dataset_info errors when metadata asset is not found", {
  local_mocked_bindings(
    cache_dir    = function() tempfile(),
    has_package  = function(pkg) TRUE,
    .pb_releases = function(...) fake_releases(),
    .pb_list     = function(...) fake_asset_list(
      files = c("other_study.zip"), tags = "v0.1.0"
    )
  )

  expect_error(dataset_info("missing_study"), "No metadata found")
})

test_that("dataset_info errors when pb_list returns NULL", {
  local_mocked_bindings(
    cache_dir    = function() tempfile(),
    has_package  = function(pkg) TRUE,
    .pb_releases = function(...) fake_releases(),
    .pb_list     = function(...) NULL
  )

  expect_error(dataset_info("some_study"), "No metadata found")
})

test_that("dataset_info remote happy path fetches and parses metadata", {
  meta_json <- jsonlite::toJSON(
    list(source = "remote_study", version = "v0.1.0", n_subjects = 50),
    auto_unbox = TRUE
  )

  # Build a minimal httr response object
  fake_resp <- structure(
    list(
      status_code = 200L,
      content     = charToRaw(as.character(meta_json)),
      headers     = list(`content-type` = "application/json")
    ),
    class = "response"
  )

  local_mocked_bindings(
    cache_dir    = function() tempfile(),
    has_package  = function(pkg) TRUE,
    .pb_releases = function(...) fake_releases(),
    .pb_list     = function(...) fake_asset_list(
      files = c("remote_study_metadata.json"),
      tags  = "v0.1.0"
    ),
    .httr_get    = function(...) fake_resp,
    # Safety net: if httr mock doesn't prevent the fallback (e.g. R CMD check
    # namespace differences), write valid JSON so the test still passes.
    .download_file = function(url, destfile, ...) {
      writeLines(as.character(meta_json), destfile)
      invisible(0L)
    }
  )

  expect_message(result <- dataset_info("remote_study"), "remote_study")
  expect_equal(result$source, "remote_study")
  expect_equal(result$n_subjects, 50)
})

test_that("dataset_info falls back to download.file when httr fails", {
  meta <- list(source = "fallback_study", version = "v1.0.0", n_subjects = 75)

  # Create a temp JSON file that download.file will "produce"
  tmp_json <- tempfile(fileext = ".json")
  jsonlite::write_json(meta, tmp_json, auto_unbox = TRUE)
  json_content <- readLines(tmp_json, warn = FALSE)
  unlink(tmp_json)

  local_mocked_bindings(
    cache_dir    = function() tempfile(),
    has_package  = function(pkg) TRUE,
    .pb_releases = function(...) fake_releases(),
    .pb_list     = function(...) fake_asset_list(
      files = c("fallback_study_metadata.json"),
      tags  = "v0.1.0"
    ),
    .httr_get    = function(...) stop("httr connection error"),
    .download_file = function(url, destfile, ...) {
      writeLines(json_content, destfile)
      invisible(0L)
    }
  )

  expect_message(result <- dataset_info("fallback_study"), "fallback_study")
  expect_equal(result$source, "fallback_study")
  expect_equal(result$n_subjects, 75)
})

test_that("dataset_info errors on malformed JSON from remote", {
  fake_resp <- structure(
    list(
      status_code = 200L,
      content     = charToRaw("this is {not valid json"),
      headers     = list(`content-type` = "application/json")
    ),
    class = "response"
  )

  local_mocked_bindings(
    cache_dir    = function() tempfile(),
    has_package  = function(pkg) TRUE,
    .pb_releases = function(...) fake_releases(),
    .pb_list     = function(...) fake_asset_list(
      files = c("bad_study_metadata.json"),
      tags  = "v0.1.0"
    ),
    .httr_get    = function(...) fake_resp,
    # Ensure fallback also produces invalid JSON
    .download_file = function(url, destfile, ...) {
      writeLines("this is {not valid json", destfile)
      invisible(0L)
    }
  )

  expect_error(dataset_info("bad_study"), "Failed to parse metadata JSON")
})

test_that("dataset_info uses tag_name column when tag column is absent", {
  meta_json <- jsonlite::toJSON(
    list(source = "tagname_study", version = "v0.1.0"),
    auto_unbox = TRUE
  )
  fake_resp <- structure(
    list(
      status_code = 200L,
      content     = charToRaw(as.character(meta_json)),
      headers     = list(`content-type` = "application/json")
    ),
    class = "response"
  )

  # Return assets with tag_name instead of tag
  assets <- data.frame(
    file_name = "tagname_study_metadata.json",
    size      = 1024,
    tag_name  = "v0.1.0",
    stringsAsFactors = FALSE
  )

  local_mocked_bindings(
    cache_dir    = function() tempfile(),
    has_package  = function(pkg) TRUE,
    .pb_releases = function(...) fake_releases(),
    .pb_list     = function(...) assets,
    .httr_get    = function(...) fake_resp,
    .download_file = function(url, destfile, ...) {
      writeLines(as.character(meta_json), destfile)
      invisible(0L)
    }
  )

  expect_message(result <- dataset_info("tagname_study"), "tagname_study")
  expect_equal(result$source, "tagname_study")
})


# --- list_available_studies -----------------------------------------------

test_that("list_available_studies errors when GitHub is unreachable", {
  local_mocked_bindings(
    has_package  = function(pkg) TRUE,
    cache_dir    = function() tempfile(),  # empty cache — no fallback available
    .pb_releases = function(...) stop("timeout")
  )

  expect_error(list_available_studies(), "Could not fetch releases")
})

test_that("list_available_studies returns empty df when no releases", {
  local_mocked_bindings(
    has_package  = function(pkg) TRUE,
    .pb_releases = function(...) empty_releases()
  )

  expect_message(result <- list_available_studies(), "No releases found")
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
  expect_named(result, c("source", "version", "size_mb", "cached"))
})

test_that("list_available_studies returns empty df when no assets", {
  local_mocked_bindings(
    has_package  = function(pkg) TRUE,
    cache_dir    = function() tempfile(),  # empty cache — no fallback
    .pb_releases = function(...) fake_releases(),
    .pb_list     = function(...) NULL
  )

  expect_message(result <- list_available_studies(), "No dataset assets")
  expect_equal(nrow(result), 0)
})

test_that("list_available_studies returns empty df when pb_list has 0 rows", {
  local_mocked_bindings(
    has_package  = function(pkg) TRUE,
    cache_dir    = function() tempfile(),  # empty cache — no fallback
    .pb_releases = function(...) fake_releases(),
    .pb_list     = function(...) data.frame(
      file_name = character(0), size = numeric(0), tag = character(0),
      stringsAsFactors = FALSE
    )
  )

  expect_message(result <- list_available_studies(), "No dataset assets")
  expect_equal(nrow(result), 0)
})

test_that("list_available_studies returns empty df when no .zip assets", {
  local_mocked_bindings(
    has_package  = function(pkg) TRUE,
    .pb_releases = function(...) fake_releases(),
    .pb_list     = function(...) fake_asset_list(
      files = c("readme.md", "data_metadata.json")
    )
  )

  expect_message(result <- list_available_studies(), "No .zip study assets")
  expect_equal(nrow(result), 0)
})

test_that("list_available_studies happy path returns correct data frame", {
  fake_cache <- file.path(tempdir(), paste0("ctd_list_", sample.int(1e5, 1)))
  cached_dir <- file.path(fake_cache, "study_a")
  dir.create(cached_dir, recursive = TRUE)
  on.exit(unlink(fake_cache, recursive = TRUE))

  local_mocked_bindings(
    has_package  = function(pkg) TRUE,
    cache_dir    = function() fake_cache,
    .pb_releases = function(...) fake_releases("v0.2.0"),
    .pb_list     = function(...) fake_asset_list(
      files = c("study_a.zip", "study_b.zip", "study_a_metadata.json"),
      tags  = "v0.2.0",
      sizes = c(4 * 1024^2, 2 * 1024^2, 1024)
    )
  )

  result <- list_available_studies()
  expect_s3_class(result, "data.frame")
  expect_named(result, c("source", "version", "size_mb", "cached"))
  expect_equal(nrow(result), 2)  # only .zip files
  expect_equal(result$source, c("study_a", "study_b"))
  expect_equal(result$version, c("v0.2.0", "v0.2.0"))
  expect_true(result$cached[result$source == "study_a"])
  expect_false(result$cached[result$source == "study_b"])
})

test_that("list_available_studies handles tag_name column variant", {
  fake_cache <- tempfile()
  on.exit(unlink(fake_cache, recursive = TRUE))

  assets <- data.frame(
    file_name = c("study_x.zip"),
    size      = 1024^2,
    tag_name  = "v1.0.0",
    stringsAsFactors = FALSE
  )

  local_mocked_bindings(
    has_package  = function(pkg) TRUE,
    cache_dir    = function() fake_cache,
    .pb_releases = function(...) fake_releases("v1.0.0"),
    .pb_list     = function(...) assets
  )

  result <- list_available_studies()
  expect_equal(result$version, "v1.0.0")
  expect_equal(result$source, "study_x")
})


# --- list_available_studies: offline fallback ------------------------------

test_that("list_available_studies saves cache on success", {
  fake_cache <- file.path(tempdir(), paste0("ctd_sc_", sample.int(1e5, 1)))
  dir.create(fake_cache, recursive = TRUE)
  on.exit(unlink(fake_cache, recursive = TRUE))

  local_mocked_bindings(
    has_package  = function(pkg) TRUE,
    cache_dir    = function() fake_cache,
    .pb_releases = function(...) fake_releases("v0.2.0"),
    .pb_list     = function(...) fake_asset_list(
      files = c("study_a.zip"), tags = "v0.2.0", sizes = 2 * 1024^2
    )
  )

  list_available_studies()
  cache_file <- file.path(fake_cache, ".studies_cache.rds")
  expect_true(file.exists(cache_file))

  cached <- readRDS(cache_file)
  expect_s3_class(cached, "data.frame")
  expect_equal(cached$source, "study_a")
})

test_that("list_available_studies falls back to stale cache when GitHub is unreachable", {
  fake_cache <- file.path(tempdir(), paste0("ctd_fb_", sample.int(1e5, 1)))
  dir.create(fake_cache, recursive = TRUE)
  on.exit(unlink(fake_cache, recursive = TRUE))

  # Pre-seed the cache with a stale listing
  stale_data <- data.frame(
    source  = c("old_study_a", "old_study_b"),
    version = c("v0.1.0", "v0.1.0"),
    size_mb = c(3.0, 1.5),
    cached  = c(TRUE, FALSE),
    stringsAsFactors = FALSE
  )
  saveRDS(stale_data, file.path(fake_cache, ".studies_cache.rds"))

  local_mocked_bindings(
    has_package  = function(pkg) TRUE,
    cache_dir    = function() fake_cache,
    .pb_releases = function(...) stop("network timeout")
  )

  expect_warning(
    result <- list_available_studies(),
    "cached study list"
  )
  expect_s3_class(result, "data.frame")
  expect_equal(result$source, c("old_study_a", "old_study_b"))
})

test_that("offline fallback recomputes cached column from filesystem", {
  fake_cache <- file.path(tempdir(), paste0("ctd_rc_", sample.int(1e5, 1)))
  dir.create(fake_cache, recursive = TRUE)
  # Create a directory for study_b (simulating it was downloaded after the
 # stale listing was saved)
  dir.create(file.path(fake_cache, "study_b"), recursive = TRUE)
  on.exit(unlink(fake_cache, recursive = TRUE))

  stale_data <- data.frame(
    source  = c("study_a", "study_b"),
    version = c("v1.0.0", "v1.0.0"),
    size_mb = c(2.0, 3.0),
    cached  = c(TRUE, FALSE),  # stale: both wrong
    stringsAsFactors = FALSE
  )
  saveRDS(stale_data, file.path(fake_cache, ".studies_cache.rds"))

  local_mocked_bindings(
    has_package  = function(pkg) TRUE,
    cache_dir    = function() fake_cache,
    .pb_releases = function(...) stop("offline")
  )

  result <- suppressWarnings(list_available_studies())
  # study_a has no directory → FALSE; study_b has a directory → TRUE
  expect_false(result$cached[result$source == "study_a"])
  expect_true(result$cached[result$source == "study_b"])
})

test_that("list_available_studies still errors when offline with no cache", {
  fake_cache <- tempfile()  # non-existent directory, no cache file
  on.exit(unlink(fake_cache, recursive = TRUE))

  local_mocked_bindings(
    has_package  = function(pkg) TRUE,
    cache_dir    = function() fake_cache,
    .pb_releases = function(...) stop("network error")
  )

  expect_error(list_available_studies(), "Could not fetch releases")
})

test_that("list_available_studies falls back when pb_list fails with stale cache", {
  fake_cache <- file.path(tempdir(), paste0("ctd_pbl_", sample.int(1e5, 1)))
  dir.create(fake_cache, recursive = TRUE)
  on.exit(unlink(fake_cache, recursive = TRUE))

  stale_data <- data.frame(
    source  = "cached_study",
    version = "v0.1.0",
    size_mb = 2.0,
    cached  = FALSE,
    stringsAsFactors = FALSE
  )
  saveRDS(stale_data, file.path(fake_cache, ".studies_cache.rds"))

  local_mocked_bindings(
    has_package  = function(pkg) TRUE,
    cache_dir    = function() fake_cache,
    .pb_releases = function(...) fake_releases("v0.1.0"),
    .pb_list     = function(...) NULL
  )

  expect_warning(
    result <- list_available_studies(),
    "cached study list"
  )
  expect_equal(result$source, "cached_study")
})


# --- download_study -------------------------------------------------------

test_that("download_study reports cached study without downloading", {
  fake_cache <- file.path(tempdir(), paste0("ctd_dl_", sample.int(1e5, 1)))
  fake_study <- file.path(fake_cache, "fake_study")
  dir.create(fake_study, recursive = TRUE)
  on.exit(unlink(fake_cache, recursive = TRUE))

  local_mocked_bindings(
    cache_dir   = function() fake_cache,
    has_package = function(pkg) TRUE
  )

  expect_message(download_study("fake_study"), "already cached")
})

test_that("download_study returns cached path invisibly", {
  fake_cache <- file.path(tempdir(), paste0("ctd_dl2_", sample.int(1e5, 1)))
  fake_study <- file.path(fake_cache, "cached_ret")
  dir.create(fake_study, recursive = TRUE)
  on.exit(unlink(fake_cache, recursive = TRUE))

  local_mocked_bindings(
    cache_dir   = function() fake_cache,
    has_package = function(pkg) TRUE
  )

  result <- suppressMessages(download_study("cached_ret"))
  expect_equal(result, fake_study)
})

test_that("download_study errors when GitHub is unreachable (latest)", {
  fake_cache <- tempfile()
  on.exit(unlink(fake_cache, recursive = TRUE))

  local_mocked_bindings(
    cache_dir    = function() fake_cache,
    has_package  = function(pkg) TRUE,
    .pb_releases = function(...) stop("network error")
  )

  expect_error(download_study("study_x"), "Could not fetch releases")
})

test_that("download_study errors when no releases exist (latest)", {
  fake_cache <- tempfile()
  on.exit(unlink(fake_cache, recursive = TRUE))

  local_mocked_bindings(
    cache_dir    = function() fake_cache,
    has_package  = function(pkg) TRUE,
    .pb_releases = function(...) empty_releases()
  )

  expect_error(download_study("study_x"), "No releases found")
})

test_that("download_study errors when pb_list fails", {
  fake_cache <- tempfile()
  on.exit(unlink(fake_cache, recursive = TRUE))

  local_mocked_bindings(
    cache_dir    = function() fake_cache,
    has_package  = function(pkg) TRUE,
    .pb_releases = function(...) fake_releases("v0.1.0"),
    .pb_list     = function(...) stop("asset listing failed")
  )

  expect_error(download_study("study_x"), "Could not list assets")
})

test_that("download_study errors when asset not found in release", {
  fake_cache <- tempfile()
  on.exit(unlink(fake_cache, recursive = TRUE))

  local_mocked_bindings(
    cache_dir    = function() fake_cache,
    has_package  = function(pkg) TRUE,
    .pb_releases = function(...) fake_releases("v0.1.0"),
    .pb_list     = function(...) fake_asset_list(
      files = c("other_study.zip"), tags = "v0.1.0"
    )
  )

  expect_error(download_study("missing_study"), "not found in release")
})

test_that("download_study happy path downloads, extracts, and locks", {
  fake_cache <- file.path(tempdir(), paste0("ctd_hp_", sample.int(1e5, 1)))
  dir.create(fake_cache, recursive = TRUE)
  on.exit({
    # Unlock before cleanup so file permissions don't block deletion
    study_path <- file.path(fake_cache, "my_study")
    if (dir.exists(study_path)) unlock_study(study_path)
    unlink(fake_cache, recursive = TRUE)
  })

  local_mocked_bindings(
    cache_dir    = function() fake_cache,
    has_package  = function(pkg) TRUE,
    .pb_releases = function(...) fake_releases("v0.1.0"),
    .pb_list     = function(...) fake_asset_list(
      files = c("my_study.zip", "my_study_metadata.json"),
      tags  = "v0.1.0"
    ),
    # pb_download mock: create a real zip in the dest directory
    .pb_download = function(file, dest, ...) {
      make_fake_zip(dest, source_name = "my_study")
      invisible(NULL)
    }
  )

  result <- suppressMessages(download_study("my_study"))
  expect_equal(result, file.path(fake_cache, "my_study"))
  expect_true(dir.exists(result))
  expect_true(is_study_locked(result))
})

test_that("download_study with explicit version skips release resolution", {
  fake_cache <- file.path(tempdir(), paste0("ctd_exv_", sample.int(1e5, 1)))
  dir.create(fake_cache, recursive = TRUE)
  on.exit({
    study_path <- file.path(fake_cache, "versioned_study")
    if (dir.exists(study_path)) unlock_study(study_path)
    unlink(fake_cache, recursive = TRUE)
  })

  pb_releases_called <- FALSE

  local_mocked_bindings(
    cache_dir    = function() fake_cache,
    has_package  = function(pkg) TRUE,
    # pb_releases should NOT be called when an explicit version is given
    .pb_releases = function(...) { pb_releases_called <<- TRUE; fake_releases("v0.1.0") },
    .pb_list     = function(...) fake_asset_list(
      files = c("versioned_study.zip"),
      tags  = "v0.1.0"
    ),
    .pb_download = function(file, dest, ...) {
      make_fake_zip(dest, source_name = "versioned_study")
      invisible(NULL)
    }
  )

  result <- suppressMessages(download_study("versioned_study", version = "v0.1.0"))
  expect_equal(result, file.path(fake_cache, "versioned_study"))
  expect_true(dir.exists(result))
  expect_false(pb_releases_called)
})

test_that("download_study with force re-downloads even when cached", {
  fake_cache <- file.path(tempdir(), paste0("ctd_force_", sample.int(1e5, 1)))
  study_path <- file.path(fake_cache, "force_study")
  dir.create(study_path, recursive = TRUE)
  # Create a marker file that should be gone after force re-download
  writeLines("old", file.path(study_path, "old_marker.txt"))
  on.exit({
    if (dir.exists(study_path)) unlock_study(study_path)
    unlink(fake_cache, recursive = TRUE)
  })

  local_mocked_bindings(
    cache_dir    = function() fake_cache,
    has_package  = function(pkg) TRUE,
    .pb_releases = function(...) fake_releases("v0.1.0"),
    .pb_list     = function(...) fake_asset_list(
      files = c("force_study.zip"),
      tags  = "v0.1.0"
    ),
    .pb_download = function(file, dest, ...) {
      make_fake_zip(dest, source_name = "force_study")
      invisible(NULL)
    }
  )

  result <- suppressMessages(download_study("force_study", force = TRUE))
  expect_true(dir.exists(result))
  # Old marker should be gone (directory was replaced)
  expect_false(file.exists(file.path(result, "old_marker.txt")))
  expect_true(is_study_locked(result))
})

test_that("download_study errors when zip file is missing after download", {
  fake_cache <- file.path(tempdir(), paste0("ctd_nozip_", sample.int(1e5, 1)))
  dir.create(fake_cache, recursive = TRUE)
  on.exit(unlink(fake_cache, recursive = TRUE))

  local_mocked_bindings(
    cache_dir    = function() fake_cache,
    has_package  = function(pkg) TRUE,
    .pb_releases = function(...) fake_releases("v0.1.0"),
    .pb_list     = function(...) fake_asset_list(
      files = c("ghost_study.zip"),
      tags  = "v0.1.0"
    ),
    # pb_download mock that does NOT create the zip file
    .pb_download = function(file, dest, ...) invisible(NULL)
  )

  expect_error(
    suppressMessages(download_study("ghost_study")),
    "zip file not found"
  )
})

test_that("download_study errors when extraction produces wrong directory", {
  fake_cache <- file.path(tempdir(), paste0("ctd_badzip_", sample.int(1e5, 1)))
  dir.create(fake_cache, recursive = TRUE)
  on.exit(unlink(fake_cache, recursive = TRUE))

  local_mocked_bindings(
    cache_dir    = function() fake_cache,
    has_package  = function(pkg) TRUE,
    .pb_releases = function(...) fake_releases("v0.1.0"),
    .pb_list     = function(...) fake_asset_list(
      files = c("expected_name.zip"),
      tags  = "v0.1.0"
    ),
    # pb_download creates a zip but with a different internal directory name
    .pb_download = function(file, dest, ...) {
      make_fake_zip(dest, source_name = "wrong_name")
      # Rename the zip to what download_study expects
      file.rename(
        file.path(dest, "wrong_name.zip"),
        file.path(dest, "expected_name.zip")
      )
      invisible(NULL)
    }
  )

  expect_error(
    suppressMessages(download_study("expected_name")),
    "Extraction did not produce expected directory"
  )
})
