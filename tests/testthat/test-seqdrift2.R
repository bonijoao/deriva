run_seqdrift2 <- function(x, ...) {
  m <- drift_method("seqdrift2"); params <- m$params
  dots <- list(...); params[names(dots)] <- dots
  run_engine(m, m$init(params), x)
}

test_that("seqdrift2 registered as a distribution method with defaults", {
  m <- drift_method("seqdrift2")
  expect_identical(m$signal_type, "distribution")
  expect_identical(m$params$delta, 0.01)
  expect_identical(m$params$block_size, 200)
})

test_that("seqdrift2 warning is all NA and there is no NA warm-up", {
  set.seed(1); out <- run_seqdrift2(stats::rnorm(500))
  expect_true(all(is.na(out$signals$.warning)))   # no warning level
  expect_false(any(is.na(out$signals$.drift)))    # window-based -> FALSE, not NA
})

test_that("seqdrift2 detects an error-rate jump after the change point", {
  set.seed(123); x <- c(stats::rbinom(600, 1, 0.05), stats::rbinom(600, 1, 0.5))
  out <- run_seqdrift2(x)
  d <- which(out$signals$.drift)
  expect_true(any(d > 600))
  expect_lt(length(d), 10)
})

test_that("seqdrift2 keeps few detections on a stationary stream", {
  set.seed(7); x <- stats::rbinom(2000, 1, 0.2)
  out <- run_seqdrift2(x)
  expect_lt(length(which(out$signals$.drift)), 5)
})

# --- the Bernstein epsilon shrinks with more data and is finite ---

test_that("seqdrift2_epsilon is a positive, finite bound", {
  e <- seqdrift2_epsilon(N = 200, variance = 0.1, delta = 0.01, num_tests = 3)
  expect_true(is.finite(e) && e > 0)
})
