# --- Helpers -----------------------------------------------------------
make_fake_study <- function() {
  base <- file.path(tempdir(), paste0("study_", sample.int(1e5, 1)))
  domain <- file.path(base, "adam")
  dir.create(domain, recursive = TRUE)
  # Write a tiny parquet so ConnectorFS has something to work with
  if (requireNamespace("arrow", quietly = TRUE)) {
    arrow::write_parquet(
      data.frame(x = 1:3),
      file.path(domain, "dummy.parquet")
    )
  }
  base
}

# --- In-memory lock / unlock / status ---------------------------------

test_that("lock_study locks and is_study_locked detects it", {
  study <- make_fake_study()
  on.exit(unlink(study, recursive = TRUE), add = TRUE)

  expect_false(is_study_locked(study))
  lock_study(study)
  expect_true(is_study_locked(study))
})

test_that("unlock_study removes the lock", {
  study <- make_fake_study()
  on.exit(unlink(study, recursive = TRUE), add = TRUE)

  lock_study(study)
  expect_true(is_study_locked(study))

  unlock_study(study)
  expect_false(is_study_locked(study))
})

test_that("lock_study on non-existent path warns and returns FALSE", {
  bad_path <- file.path(tempdir(), "no_such_dir_abc123")
  expect_warning(result <- lock_study(bad_path), "does not exist")
  expect_false(result)
})

test_that("locking the same path twice is idempotent", {
  study <- make_fake_study()
  on.exit(unlink(study, recursive = TRUE), add = TRUE)

  lock_study(study)
  lock_study(study)
  expect_true(is_study_locked(study))

  # Unlocking once is sufficient

  unlock_study(study)
  expect_false(is_study_locked(study))
})

test_that("get_lock_status reports correct state", {
  study <- make_fake_study()
  on.exit(unlink(study, recursive = TRUE), add = TRUE)

  status <- get_lock_status(study)
  expect_false(status$locked)
  expect_equal(status$path, study)

  lock_study(study)
  status <- get_lock_status(study)
  expect_true(status$locked)
})

test_that("lock_all_studies locks every subfolder", {
  base <- file.path(tempdir(), paste0("multi_", sample.int(1e5, 1)))
  dir.create(file.path(base, "study_a"), recursive = TRUE)
  dir.create(file.path(base, "study_b"), recursive = TRUE)
  on.exit(unlink(base, recursive = TRUE), add = TRUE)

  locked <- lock_all_studies(base)

  expect_true(is_study_locked(file.path(base, "study_a")))
  expect_true(is_study_locked(file.path(base, "study_b")))

  # Clean up in-memory locks

  unlock_study(file.path(base, "study_a"))
  unlock_study(file.path(base, "study_b"))
})

test_that("can_write_study returns TRUE when unlocked, FALSE when locked", {
  study <- make_fake_study()
  on.exit(unlink(study, recursive = TRUE), add = TRUE)

  expect_true(can_write_study(study))

  lock_study(study)
  expect_warning(
    result <- can_write_study(study),
    "study folder is locked"
  )
  expect_false(result)

  unlock_study(study)
})

# --- ConnectorLockedFS S3 methods ------------------------------------

test_that("write_cnt on a locked connector errors", {
  skip_if_not_installed("connector")
  skip_if_not_installed("arrow")

  study <- make_fake_study()
  on.exit({
    unlock_study(study)
    unlink(study, recursive = TRUE)
  }, add = TRUE)

  # Build a ConnectorFS pointing at the study's adam/ subdirectory
  cfg <- list(
    datasources = list(
      list(
        name = "adam",
        backend = list(type = "connector_fs", path = file.path(study, "adam"))
      )
    )
  )
  conn <- connector::connect(cfg)

  # Wrap it with the lock class, same as the package does
  class(conn$adam) <- c("ConnectorLockedFS", class(conn$adam))
  attr(conn$adam, "study_path") <- study

  # Lock the study
  lock_study(study)

  expect_error(
    suppressWarnings(write_cnt(conn$adam, data.frame(a = 1), "test_file")),
    "locked"
  )
})

test_that("remove_cnt on a locked connector errors", {
  skip_if_not_installed("connector")
  skip_if_not_installed("arrow")

  study <- make_fake_study()
  on.exit({
    unlock_study(study)
    unlink(study, recursive = TRUE)
  }, add = TRUE)

  cfg <- list(
    datasources = list(
      list(
        name = "adam",
        backend = list(type = "connector_fs", path = file.path(study, "adam"))
      )
    )
  )
  conn <- connector::connect(cfg)
  class(conn$adam) <- c("ConnectorLockedFS", class(conn$adam))
  attr(conn$adam, "study_path") <- study

  lock_study(study)

  expect_error(
    suppressWarnings(remove_cnt(conn$adam, "dummy")),
    "locked"
  )
})

test_that("write_cnt succeeds on an unlocked connector", {
  skip_if_not_installed("connector")
  skip_if_not_installed("arrow")

  study <- make_fake_study()
  on.exit(unlink(study, recursive = TRUE), add = TRUE)

  cfg <- list(
    datasources = list(
      list(
        name = "adam",
        backend = list(type = "connector_fs", path = file.path(study, "adam"))
      )
    )
  )
  conn <- connector::connect(cfg)
  class(conn$adam) <- c("ConnectorLockedFS", class(conn$adam))
  attr(conn$adam, "study_path") <- study

  # Study is NOT locked — write should succeed
  expect_no_error(
    write_cnt(conn$adam, data.frame(a = 1:3), "new_data")
  )

  # Verify the file was actually written
  files <- conn$adam$list_content_cnt()
  expect_true("new_data" %in% tools::file_path_sans_ext(files))
})

test_that("remove_cnt succeeds on an unlocked connector", {
  skip_if_not_installed("connector")
  skip_if_not_installed("arrow")

  study <- make_fake_study()
  on.exit(unlink(study, recursive = TRUE), add = TRUE)

  cfg <- list(
    datasources = list(
      list(
        name = "adam",
        backend = list(type = "connector_fs", path = file.path(study, "adam"))
      )
    )
  )
  conn <- connector::connect(cfg)
  class(conn$adam) <- c("ConnectorLockedFS", class(conn$adam))
  attr(conn$adam, "study_path") <- study

  # dummy.parquet was created by make_fake_study()
  expect_no_error(
    remove_cnt(conn$adam, "dummy.parquet")
  )
})

# --- Full lock-unlock-write cycle -------------------------------------

test_that("lock then unlock then write succeeds end-to-end", {
  skip_if_not_installed("connector")
  skip_if_not_installed("arrow")

  study <- make_fake_study()
  on.exit({
    unlock_study(study)
    unlink(study, recursive = TRUE)
  }, add = TRUE)

  cfg <- list(
    datasources = list(
      list(
        name = "adam",
        backend = list(type = "connector_fs", path = file.path(study, "adam"))
      )
    )
  )
  conn <- connector::connect(cfg)
  class(conn$adam) <- c("ConnectorLockedFS", class(conn$adam))
  attr(conn$adam, "study_path") <- study

  # 1. Lock - write should fail
  lock_study(study)
  expect_error(
    suppressWarnings(write_cnt(conn$adam, data.frame(z = 1), "blocked")),
    "locked"
  )

  # 2. Unlock — write should now succeed
  unlock_study(study)
  expect_no_error(
    write_cnt(conn$adam, data.frame(z = 1), "allowed")
  )
})

# --- .set_permissions (Unix only) -----------------------------------------
# These tests require the study to live under cache_dir() so that
# .set_permissions() actually applies Sys.chmod().  They are skipped
# on Windows where file-permission bits are not meaningful.

make_cache_study <- function() {
  cd <- cache_dir()
  study <- file.path(cd, paste0("perm_test_", sample.int(1e5, 1)))
  domain <- file.path(study, "adam")
  dir.create(domain, recursive = TRUE)
  writeLines("placeholder", file.path(domain, "dummy.parquet"))
  study
}

test_that(".set_permissions makes files read-only on Unix", {
  skip_on_os("windows")

  study <- make_cache_study()
  on.exit({
    # Restore write permissions before cleanup
    .set_permissions(study, read_only = FALSE)
    unlock_study(study)
    unlink(study, recursive = TRUE)
  }, add = TRUE)

  .set_permissions(study, read_only = TRUE)

  f <- file.path(study, "adam", "dummy.parquet")
  info <- file.info(f)
  # Owner write bit (0200) should be off
  expect_equal(as.integer(info$mode) %% 1000L %/% 100L %% 2L, 0L)
})

test_that(".set_permissions restores write permissions on Unix", {
  skip_on_os("windows")

  study <- make_cache_study()
  on.exit({
    unlock_study(study)
    unlink(study, recursive = TRUE)
  }, add = TRUE)

  .set_permissions(study, read_only = TRUE)
  .set_permissions(study, read_only = FALSE)

  f <- file.path(study, "adam", "dummy.parquet")
  info <- file.info(f)
  # File should be 0644 — owner write bit (0200) should be on
  mode_oct <- format(info$mode, digits = 4)
  expect_equal(mode_oct, "644")
})

test_that(".set_permissions sets directories to 0555 / 0755 on Unix", {
  skip_on_os("windows")

  study <- make_cache_study()
  on.exit({
    .set_permissions(study, read_only = FALSE)
    unlock_study(study)
    unlink(study, recursive = TRUE)
  }, add = TRUE)

  .set_permissions(study, read_only = TRUE)

  d <- file.path(study, "adam")
  mode_oct <- format(file.info(d)$mode, digits = 4)
  expect_equal(mode_oct, "555")

  .set_permissions(study, read_only = FALSE)
  mode_oct <- format(file.info(d)$mode, digits = 4)
  expect_equal(mode_oct, "755")
})

test_that("lock_study + unlock_study cycle applies permissions on Unix", {
  skip_on_os("windows")

  study <- make_cache_study()
  on.exit({
    .set_permissions(study, read_only = FALSE)
    unlock_study(study)
    unlink(study, recursive = TRUE)
  }, add = TRUE)

  lock_study(study)

  f <- file.path(study, "adam", "dummy.parquet")
  mode_locked <- format(file.info(f)$mode, digits = 4)
  expect_equal(mode_locked, "444")

  unlock_study(study)

  mode_unlocked <- format(file.info(f)$mode, digits = 4)
  expect_equal(mode_unlocked, "644")
})

test_that(".set_permissions is a no-op for paths outside cache_dir", {
  skip_on_os("windows")

  # Create a study in tempdir(), NOT under cache_dir()
  study <- make_fake_study()
  on.exit(unlink(study, recursive = TRUE), add = TRUE)

  f <- file.path(study, "adam", "dummy.parquet")
  skip_if(!file.exists(f), "arrow not available to create parquet")

  mode_before <- format(file.info(f)$mode, digits = 4)
  .set_permissions(study, read_only = TRUE)
  mode_after <- format(file.info(f)$mode, digits = 4)

  # Permissions should be unchanged
  expect_equal(mode_after, mode_before)
})

test_that(".set_permissions is a no-op for non-existent path", {
  skip_on_os("windows")

  result <- .set_permissions(file.path(tempdir(), "no_such_dir"), read_only = TRUE)
  expect_null(result)
})
