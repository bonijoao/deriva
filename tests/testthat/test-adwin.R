run_adwin <- function(x, ...) {
  m <- drift_method("adwin"); params <- m$params
  dots <- list(...); params[names(dots)] <- dots
  run_engine(m, m$init(params), x)
}

test_that("adwin registered as a distribution method with defaults", {
  m <- drift_method("adwin")
  expect_identical(m$signal_type, "distribution")
  expect_identical(m$params$delta, 0.002)
  expect_identical(m$params$clock, 32)
  expect_identical(m$params$max_buckets, 5)
  expect_identical(m$params$min_window_length, 5)
  expect_identical(m$params$grace_period, 10)
})

test_that("adwin warning is all NA and there is no NA warm-up", {
  out <- run_adwin(stats::rnorm(200))
  expect_true(all(is.na(out$signals$.warning)))   # no warning level
  expect_false(any(is.na(out$signals$.drift)))    # window-based -> FALSE, not NA
})

test_that("adwin detects a mean shift after the change point", {
  set.seed(1); x <- c(stats::rnorm(500, 0, 1), stats::rnorm(500, 3, 1))
  out <- run_adwin(x)
  d <- which(out$signals$.drift)
  expect_true(any(d > 500))
  expect_lt(length(d), 30)
})
