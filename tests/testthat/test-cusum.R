run_cusum <- function(x, ...) {
  m <- drift_method("cusum")
  params <- m$params; dots <- list(...); params[names(dots)] <- dots
  run_engine(m, m$init(params), x)
}

test_that("cusum is a distribution method with reference defaults", {
  m <- drift_method("cusum")
  expect_identical(m$signal_type, "distribution")
  expect_identical(m$params$min_instances, 30)
  expect_identical(m$params$delta, 0.005)
  expect_identical(m$params$threshold, 50)
})

test_that("cusum warning column is all NA (no warning level)", {
  out <- run_cusum(stats::rnorm(200))
  expect_true(all(is.na(out$signals$.warning)))
})

test_that("cusum emits NA during warm-up", {
  out <- run_cusum(stats::rnorm(40))
  expect_true(all(is.na(out$signals$.drift[1:28])))
})

test_that("cusum detects an upward mean shift", {
  set.seed(1); x <- c(stats::rnorm(500, 0, 1), stats::rnorm(500, 3, 1))
  out <- run_cusum(x)
  expect_true(any(which(out$signals$.drift) > 500))
})

test_that("cusum accepts a 0/1 error stream (dual-use)", {
  x <- c(stats::rbinom(500, 1, 0.05), stats::rbinom(500, 1, 0.5))
  expect_no_error(run_cusum(x))
})
