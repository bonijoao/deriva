run_rddm <- function(x, ...) {
  m <- drift_method("rddm"); params <- m$params
  dots <- list(...); params[names(dots)] <- dots
  run_engine(m, m$init(params), x)
}

test_that("rddm registered as error method with DDM-style defaults", {
  m <- drift_method("rddm")
  expect_identical(m$signal_type, "error")
  expect_identical(m$params$min_instances, 129)
  expect_identical(m$params$warning_level, 1.773)
  expect_identical(m$params$out_control_level, 2.258)
})

test_that("rddm detects an error-rate jump after the change point", {
  set.seed(123); x <- c(stats::rbinom(500, 1, 0.05), stats::rbinom(500, 1, 0.5))
  out <- run_rddm(x)
  expect_true(any(which(out$signals$.drift) > 500))
})

test_that("rddm emits NA during warm-up", {
  out <- run_rddm(stats::rbinom(150, 1, 0.1))
  expect_true(all(is.na(out$signals$.drift[1:128])))
})
