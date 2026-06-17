run_seed <- function(x, ...) {
  m <- drift_method("seed"); params <- m$params
  dots <- list(...); params[names(dots)] <- dots
  run_engine(m, m$init(params), x)
}

test_that("seed registered as a distribution method with defaults", {
  m <- drift_method("seed")
  expect_identical(m$signal_type, "distribution")
  expect_identical(m$params$delta, 0.05)
  expect_identical(m$params$block_size, 32)
  expect_identical(m$params$epsilon_prime, 0.01)
  expect_identical(m$params$alpha, 0.8)
  expect_identical(m$params$compression_term, 75)
})

test_that("seed warning is all NA and there is no NA warm-up", {
  out <- run_seed(stats::rnorm(200))
  expect_true(all(is.na(out$signals$.warning)))   # no warning level
  expect_false(any(is.na(out$signals$.drift)))    # window-based -> FALSE, not NA
})

test_that("seed detects an error-rate jump after the change point", {
  set.seed(123); x <- c(stats::rbinom(500, 1, 0.05), stats::rbinom(500, 1, 0.5))
  out <- run_seed(x)
  d <- which(out$signals$.drift)
  expect_true(any(d > 500))
  expect_lt(length(d), 30)
})

test_that("seed detects a mean shift after the change point", {
  set.seed(1); x <- c(stats::rnorm(500, 0, 1), stats::rnorm(500, 3, 1))
  out <- run_seed(x)
  expect_true(any(which(out$signals$.drift) > 500))
})

test_that("seed keeps few detections on a stationary stream", {
  set.seed(7); x <- stats::rbinom(2000, 1, 0.2)
  out <- run_seed(x)
  expect_lt(length(which(out$signals$.drift)), 5)
})
