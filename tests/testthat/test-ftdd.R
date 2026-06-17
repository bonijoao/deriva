run_ftdd <- function(x, ...) {
  m <- drift_method("ftdd"); params <- m$params
  dots <- list(...); params[names(dots)] <- dots
  run_engine(m, m$init(params), x)
}

test_that("ftdd registered as error method with stepd-style defaults", {
  m <- drift_method("ftdd")
  expect_identical(m$signal_type, "error")
  expect_identical(m$params$window_size, 30)
  expect_identical(m$params$warning_level, 0.05)
  expect_identical(m$params$out_control_level, 0.003)
})

test_that("ftdd detects an error-rate jump after the change point", {
  set.seed(123); x <- c(stats::rbinom(500, 1, 0.05), stats::rbinom(500, 1, 0.5))
  out <- run_ftdd(x)
  expect_true(any(which(out$signals$.drift) > 500))
})

test_that("ftdd keeps a low false-alarm rate on a stationary stream", {
  # At out_control_level=0.003 over ~970 post-warm-up steps a few chance
  # detections are expected; assert the RATE is small, not exactly zero.
  set.seed(7); x <- stats::rbinom(1000, 1, 0.1)
  out <- run_ftdd(x)
  expect_lt(mean(out$signals$.drift, na.rm = TRUE), 0.05)
})

test_that("ftdd emits NA during warm-up", {
  out <- run_ftdd(stats::rbinom(40, 1, 0.1))
  expect_true(all(is.na(out$signals$.drift[1:28])))
})
