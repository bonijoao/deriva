run_stepd <- function(x, ...) {
  m <- drift_method("stepd"); params <- m$params
  dots <- list(...); params[names(dots)] <- dots
  run_engine(m, m$init(params), x)
}

test_that("stepd registered as error method with defaults", {
  m <- drift_method("stepd")
  expect_identical(m$signal_type, "error")
  expect_identical(m$params$window_size, 30)
  expect_identical(m$params$warning_level, 0.05)
  expect_identical(m$params$out_control_level, 0.003)
})

test_that("stepd detects an error-rate jump after the change point", {
  set.seed(123); x <- c(stats::rbinom(500, 1, 0.05), stats::rbinom(500, 1, 0.5))
  out <- run_stepd(x)
  expect_true(any(which(out$signals$.drift) > 500))
})

test_that("stepd emits NA during warm-up", {
  out <- run_stepd(stats::rbinom(40, 1, 0.1))
  expect_true(all(is.na(out$signals$.drift[1:28])))
})
