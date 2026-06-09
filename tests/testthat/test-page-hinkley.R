run_ph <- function(x, ...) {
  m <- drift_method("page_hinkley")
  params <- m$params; dots <- list(...); params[names(dots)] <- dots
  run_engine(m, m$init(params), x)
}

test_that("page_hinkley is a distribution method with reference defaults", {
  m <- drift_method("page_hinkley")
  expect_identical(m$signal_type, "distribution")
  expect_identical(m$params$min_instances, 30)
  expect_identical(m$params$delta, 0.05)
  expect_identical(m$params$threshold, 50)
  expect_identical(m$params$alpha, 1)
})

test_that("page_hinkley warning column is all NA (no warning level)", {
  out <- run_ph(stats::rnorm(200))
  expect_true(all(is.na(out$signals$.warning)))
})

test_that("page_hinkley emits NA during warm-up", {
  out <- run_ph(stats::rnorm(40))
  expect_true(all(is.na(out$signals$.drift[1:28])))
})

test_that("page_hinkley detects an upward mean shift", {
  x <- c(stats::rnorm(500, 0, 1), stats::rnorm(500, 3, 1))
  set.seed(1); out <- run_ph(x)
  expect_true(any(which(out$signals$.drift) > 500))
})

test_that("page_hinkley accepts a 0/1 error stream (dual-use)", {
  x <- c(stats::rbinom(500, 1, 0.05), stats::rbinom(500, 1, 0.5))
  expect_no_error(run_ph(x))
})
