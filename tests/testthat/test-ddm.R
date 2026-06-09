run_ddm <- function(x, ...) {
  m <- drift_method("ddm")
  params <- m$params
  dots <- list(...)
  params[names(dots)] <- dots
  run_engine(m, m$init(params), x)
}

test_that("ddm is registered with the right contract", {
  m <- drift_method("ddm")
  expect_identical(m$signal_type, "error")
  expect_identical(m$params$min_instances, 30)
  expect_identical(m$params$warning_level, 2)
  expect_identical(m$params$out_control_level, 3)
})

test_that("ddm emits NA during warm-up", {
  out <- run_ddm(rep(0, 40))
  # sample_count starts at 1 and is incremented BEFORE the warm-up check, so
  # processing obs k leaves sample_count = k + 1: obs 1..28 return NA and
  # obs 29 (sample_count = 30) is the first evaluated one.
  expect_true(all(is.na(out$signals$.drift[1:28])))
  expect_false(any(is.na(out$signals$.drift[29:40])))
})

test_that("ddm stays quiet on a stable low-error stream", {
  set.seed(123)
  x <- stats::rbinom(500, 1, 0.05)
  out <- run_ddm(x)
  expect_false(any(out$signals$.drift, na.rm = TRUE))
})

test_that("ddm detects an abrupt error-rate jump, after the change point", {
  set.seed(123)
  x <- c(stats::rbinom(500, 1, 0.05), stats::rbinom(500, 1, 0.5))
  out <- run_ddm(x)
  first_drift <- which(out$signals$.drift)[1]
  expect_gt(first_drift, 500)
  expect_lt(first_drift, 600) # detection delay sane for an abrupt jump
})

test_that("ddm resets after a drift and can detect again", {
  set.seed(42)
  x <- c(stats::rbinom(300, 1, 0.05), stats::rbinom(300, 1, 0.6),
         stats::rbinom(300, 1, 0.05), stats::rbinom(300, 1, 0.6))
  out <- run_ddm(x)
  drifts <- which(out$signals$.drift)
  expect_gte(length(drifts), 2)
  expect_true(any(drifts > 900)) # detected the second drift too
})
